const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin
admin.initializeApp();

// Initialize OpenAI with API key from Firebase config
let openai;
async function initializeOpenAI() {
  if (!openai) {
    // Try to get API key from Firebase config
    const apiKey = functions.config().openai?.api_key;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not configured in Firebase Functions');
    }
    openai = new OpenAI({
      apiKey: apiKey,
    });
  }
  return openai;
}

/**
 * Analyze plant photo using OpenAI GPT-4 Vision API
 */
exports.analyzePlantPhoto = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      // Initialize OpenAI with API key from secrets
      const openaiClient = await initializeOpenAI();
      
      // Check if API key is configured
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const { base64Image, plantName } = req.body;

      if (!base64Image) {
        return res.status(400).json({ error: 'Base64 image is required' });
      }

      console.log('🔍 Starting plant photo analysis');
      console.log('🔍 Plant name:', plantName);
      console.log('🔍 Image length:', base64Image.length);

      const response = await openaiClient.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Analyze this plant photo and provide detailed care recommendations. ${plantName ? `This is a ${plantName}.` : ''} You MUST follow this EXACT format:

Plant: [Identify the plant and provide the common name and scientific name if possible]
Description: [Provide a detailed description of the plant including its appearance, characteristics, and general information]
Care Recommendations:
   - Watering: [Specific watering instructions]
   - Light Requirements: [Light needs]
   - Temperature: [Temperature preferences]
   - Soil: [Soil type and requirements]
   - Fertilizing: [Fertilizer needs]
   - Humidity: [Humidity requirements]
   - Growth Rate / Size: [Growth characteristics]
   - Blooming: [Flowering information if applicable]
Interesting Facts: Provide exactly 4 facts about this plant type. Make 3 educational and 1 funny. Format as simple sentences without any special characters, numbers, or bullet points.

IMPORTANT: You MUST start with "Plant:" and "Description:" sections before the Care Recommendations. If you cannot identify the exact plant, provide a general description based on what you can see in the image.

HEALTH ASSESSMENT: Based on the plant's appearance, assess if it appears healthy, thriving, or if there are any visible problems. Be specific about what you observe regarding the plant's health status.`
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`,
                },
              },
            ],
          },
        ],
        max_tokens: 1000,
        temperature: 0.7,
      });

      const content = response.choices[0].message.content;
      console.log('✅ Plant analysis successful');

      // Parse the AI response to extract structured information
      const recommendations = parseAIResponse(content);

      res.json({
        success: true,
        recommendations,
        rawResponse: content
      });

    } catch (error) {
      console.error('❌ Plant Photo Analysis Error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });
});

/**
 * Generate plant content without image
 */
exports.generatePlantContent = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      // Initialize OpenAI with API key from secrets
      const openaiClient = await initializeOpenAI();
      
      // Check if API key is configured
      if (!openaiClient.apiKey) {
        throw new Error('OPENAI_API_KEY is not configured');
      }

      const { plantName, species } = req.body;

      if (!plantName) {
        return res.status(400).json({ error: 'Plant name is required' });
      }

      console.log('🔍 Generating content for plant:', plantName, species);

      const response = await openaiClient.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: `Provide detailed care recommendations for a ${plantName}${species ? ` (${species})` : ''}. You MUST follow this EXACT format:

Plant: [Identify the plant and provide the common name and scientific name if applicable]
Description: [Provide a detailed description of the plant including its appearance, characteristics, and general information]
Care Recommendations:
   - Watering: [Specific watering instructions]
   - Light Requirements: [Light needs]
   - Temperature: [Temperature preferences]
   - Soil: [Soil type and requirements]
   - Fertilizing: [Fertilizer needs]
   - Humidity: [Humidity requirements]
   - Growth Rate / Size: [Growth characteristics]
   - Blooming: [Flowering information if applicable]
Interesting Facts: Provide exactly 4 facts about this plant type. Make 3 educational and 1 funny. Format as simple sentences without any special characters, numbers, or bullet points.

IMPORTANT: You MUST start with "Plant:" and "Description:" sections before the Care Recommendations.`
        }
        ],
        max_tokens: 1000,
        temperature: 0.7,
      });

      const content = response.choices[0].message.content;
      console.log('✅ Plant content generation successful');

      const recommendations = parseAIResponse(content);

      res.json({
        success: true,
        recommendations,
        rawResponse: content
      });

    } catch (error) {
      console.error('❌ Plant Content Generation Error:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  });
});

/**
 * Parse AI response to extract structured information
 * Maps to the expected Flutter app format
 */
function parseAIResponse(content) {
  try {
    const lines = content.split('\n');
    const result = {};
    let currentSection = '';
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.startsWith('Plant:')) {
        currentSection = 'plant';
        result.plant = trimmedLine.substring(6).trim();
      } else if (trimmedLine.startsWith('Description:')) {
        currentSection = 'description';
        result.description = trimmedLine.substring(12).trim();
      } else if (trimmedLine.startsWith('Care Recommendations:')) {
        currentSection = 'careRecommendations';
        result.careRecommendations = {};
      } else if (trimmedLine.startsWith('- Watering:')) {
        result.careRecommendations.watering = trimmedLine.substring(11).trim();
      } else if (trimmedLine.startsWith('- Light Requirements:')) {
        result.careRecommendations.lightRequirements = trimmedLine.substring(20).trim();
      } else if (trimmedLine.startsWith('- Temperature:')) {
        result.careRecommendations.temperature = trimmedLine.substring(14).trim();
      } else if (trimmedLine.startsWith('- Soil:')) {
        result.careRecommendations.soil = trimmedLine.substring(7).trim();
      } else if (trimmedLine.startsWith('- Fertilizing:')) {
        result.careRecommendations.fertilizing = trimmedLine.substring(14).trim();
      } else if (trimmedLine.startsWith('- Humidity:')) {
        result.careRecommendations.humidity = trimmedLine.substring(11).trim();
      } else if (trimmedLine.startsWith('- Growth Rate / Size:')) {
        result.careRecommendations.growthRate = trimmedLine.substring(20).trim();
      } else if (trimmedLine.startsWith('- Blooming:')) {
        result.careRecommendations.blooming = trimmedLine.substring(11).trim();
      } else if (trimmedLine.startsWith('Interesting Facts:')) {
        currentSection = 'interestingFacts';
        result.interestingFacts = [];
      } else if (currentSection === 'interestingFacts' && trimmedLine.length > 0) {
        result.interestingFacts.push(trimmedLine);
      } else if (currentSection === 'careRecommendations' && trimmedLine.startsWith('-') && trimmedLine.includes(':')) {
        // Handle any additional care recommendations
        const colonIndex = trimmedLine.indexOf(':');
        const key = trimmedLine.substring(1, colonIndex).trim().toLowerCase().replace(/\s+/g, '');
        const value = trimmedLine.substring(colonIndex + 1).trim();
        if (key && value) {
          result.careRecommendations[key] = value;
        }
      }
    }
    
    // Map to expected Flutter app format
    return {
      general_description: result.description || content,
      name: result.plant || 'Plant',
      moisture_level: result.careRecommendations?.humidity || 'Moderate',
      light: result.careRecommendations?.lightRequirements || 'Bright indirect light',
      watering_frequency: _extractWateringFrequency(result.careRecommendations?.watering),
      watering_amount: 'Until soil is moist',
      specific_issues: 'No specific issues detected',
      care_tips: _formatCareTips(result.careRecommendations),
      interesting_facts: result.interestingFacts || ['Every plant is unique', 'Plants grow throughout their lifecycle', 'Proper care helps plants thrive', 'Plants can communicate with each other']
    };
  } catch (error) {
    console.error('Error parsing AI response:', error);
    return { 
      general_description: content,
      name: 'Plant',
      moisture_level: 'Moderate',
      light: 'Bright indirect light',
      watering_frequency: 7,
      watering_amount: 'Until soil is moist',
      specific_issues: 'Please check plant care manually',
      care_tips: 'Monitor soil moisture and light conditions',
      interesting_facts: ['Every plant is unique', 'Plants grow throughout their lifecycle', 'Proper care helps plants thrive', 'Plants can communicate with each other']
    };
  }
}

/**
 * Extract watering frequency from watering text
 */
function _extractWateringFrequency(wateringText) {
  if (!wateringText) return 7;
  
  const text = wateringText.toLowerCase();
  if (text.includes('every 3 days') || text.includes('3 days')) return 3;
  if (text.includes('every 5 days') || text.includes('5 days')) return 5;
  if (text.includes('every 10 days') || text.includes('10 days')) return 10;
  if (text.includes('every 14 days') || text.includes('14 days')) return 14;
  if (text.includes('weekly') || text.includes('once a week')) return 7;
  if (text.includes('daily') || text.includes('every day')) return 1;
  
  return 7; // Default
}

/**
 * Format care tips from care recommendations
 */
function _formatCareTips(careRecommendations) {
  if (!careRecommendations) return 'Follow general plant care guidelines';
  
  const tips = [];
  if (careRecommendations.watering) tips.push(`Watering: ${careRecommendations.watering}`);
  if (careRecommendations.lightRequirements) tips.push(`Light: ${careRecommendations.lightRequirements}`);
  if (careRecommendations.temperature) tips.push(`Temperature: ${careRecommendations.temperature}`);
  if (careRecommendations.soil) tips.push(`Soil: ${careRecommendations.soil}`);
  if (careRecommendations.fertilizing) tips.push(`Fertilizing: ${careRecommendations.fertilizing}`);
  if (careRecommendations.humidity) tips.push(`Humidity: ${careRecommendations.humidity}`);
  
  return tips.length > 0 ? tips.join('\n') : 'Follow general plant care guidelines';
}
