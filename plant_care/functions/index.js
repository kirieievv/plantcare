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
                text: `Analyze this plant photo and provide ONLY the following information:

Plant Name: [Be specific - what type of plant is this?]
Species: [Scientific name if visible, otherwise leave blank]

Health Assessment: [Is this plant healthy or does it have visible problems? Be specific about what you see.]

Care Recommendations: [Based on the plant's current condition, what specific care does it need?]

IMPORTANT: 
- Be confident in your plant identification
- Focus on what you can actually see in the image
- If you can see plant features, identify them specifically
- Only provide care recommendations relevant to the plant's current condition
- Never say "unable to identify" - provide your best assessment based on visible features`
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
            content: `Provide focused care recommendations for a ${plantName}${species ? ` (${species})` : ''}. Follow this format:

Plant Name: ${plantName}
Species: ${species || 'Not specified'}

Care Recommendations: [Provide specific care instructions for this plant type]

IMPORTANT: 
- Focus on practical care information
- Provide actionable advice
- Keep recommendations relevant and specific`
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
      if (trimmedLine.startsWith('Plant Name:')) {
        currentSection = 'plantName';
        result.plantName = trimmedLine.substring(12).trim();
      } else if (trimmedLine.startsWith('Species:')) {
        currentSection = 'species';
        result.species = trimmedLine.substring(8).trim();
      } else if (trimmedLine.startsWith('Health Assessment:')) {
        currentSection = 'healthAssessment';
        result.healthAssessment = trimmedLine.substring(19).trim();
      } else if (trimmedLine.startsWith('Care Recommendations:')) {
        currentSection = 'careRecommendations';
        result.careRecommendations = trimmedLine.substring(21).trim();
      } else if (currentSection === 'careRecommendations' && trimmedLine.length > 0 && !trimmedLine.startsWith('IMPORTANT:')) {
        // Append to care recommendations if we're in that section
        if (result.careRecommendations) {
          result.careRecommendations += ' ' + trimmedLine;
        } else {
          result.careRecommendations = trimmedLine;
        }
      }
    }
    
    // Map to expected Flutter app format
    return {
      general_description: result.healthAssessment || content,
      name: result.plantName || 'Plant',
      moisture_level: 'Moderate', // Default since we don't have specific humidity info
      light: 'Bright indirect light', // Default since we don't have specific light info
      watering_frequency: 7, // Default watering frequency
      watering_amount: 'Until soil is moist',
      specific_issues: result.healthAssessment?.includes('problem') || result.healthAssessment?.includes('issue') ? 'Plant needs attention' : 'No specific issues detected',
      care_tips: result.careRecommendations || 'Monitor plant health and provide appropriate care',
      interesting_facts: ['Every plant is unique', 'Plants grow throughout their lifecycle', 'Proper care helps plants thrive', 'Plants can communicate with each other']
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
