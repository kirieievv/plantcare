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

      const { base64Image, plantName, isHealthCheck } = req.body;

      if (!base64Image) {
        return res.status(400).json({ error: 'Base64 image is required' });
      }

      console.log('🔍 Starting plant photo analysis');
      console.log('🔍 Plant name:', plantName);
      console.log('🔍 Is Health Check:', isHealthCheck);
      console.log('🔍 Image length:', base64Image.length);

      // Choose prompt based on use case
      let promptText;
      if (isHealthCheck) {
        // HEALTH CHECK PROMPT - Focus on current plant condition and health
        promptText = `You are a plant health expert. Analyze this plant photo to assess its current health and condition. You MUST follow this EXACT format:

Plant: [What is the name of this plant? Look at the leaves, flowers, and overall appearance.]
Species: [What is the specific species? If you can see distinctive characteristics, provide it. If not, leave blank.]

Description: [Describe what you see in this photo - leaf color, size, flowers, any visible features.]

Plant Size Assessment:
   - Plant Size: [Small/Medium/Large - based on visible growth and maturity]
   - Pot Size: [Small/Medium/Large - estimate pot diameter in inches or cm]
   - Growth Stage: [Seedling/Young/Mature/Established]

Care Recommendations:
   - Watering: [Specific watering needs - frequency and amount in cups (200ml) based on plant size and pot size]
   - Light: [Specific light requirements - hours per day and intensity]
   - Temperature: [What temperature range?]
   - Soil: [What soil type?]
   - Fertilizing: [What fertilization approach?]
   - Humidity: [What humidity level?]
   - Growth: [What can you observe about growth and size?]
   - Blooming: [If you see flowers, describe them. If not, mention when it typically blooms.]

Interesting Facts: [4 facts about this plant type - 3 educational, 1 funny.]

HEALTH ASSESSMENT: [CRITICAL - Look at this specific plant in the image. Is it healthy, thriving, or does it have visible problems? Be specific about what you observe - leaf color, growth pattern, any damage, etc. If it looks healthy, state that clearly. If there are issues, describe what you see and what needs to be fixed.]

IMPORTANT: You CAN analyze this image. Look carefully at the plant's current condition. Focus on health assessment and any visible problems that need attention.`;
      } else {
        // NEW PLANT ANALYSIS PROMPT - Focus on identification and general care
        promptText = `You are a plant expert. Look at this plant photo and identify the plant. You MUST follow this EXACT format:

Plant: [What is the name of this plant? Look at the leaves, flowers, and overall appearance.]
Species: [What is the specific species? If you can see distinctive characteristics, provide it. If not, leave blank.]

Description: [Describe what you see in this photo - leaf color, size, flowers, any visible features.]

Plant Size Assessment:
   - Plant Size: [Small/Medium/Large - based on visible growth and maturity]
   - Pot Size: [Small/Medium/Large - estimate pot diameter in inches or cm]
   - Growth Stage: [Seedling/Young/Mature/Established]

Care Recommendations:
   - Watering: [Specific watering needs - frequency and amount in cups (200ml) based on plant size and pot size]
   - Light: [Specific light requirements - hours per day and intensity]
   - Temperature: [What temperature range?]
   - Soil: [What soil type?]
   - Fertilizing: [What fertilization approach?]
   - Humidity: [What humidity level?]
   - Growth: [What can you observe about growth and size?]
   - Blooming: [If you see flowers, describe them. If not, mention when it typically blooms.]

Interesting Facts: [4 facts about this plant type - 3 educational, 1 funny.]

HEALTH ASSESSMENT: [Is this plant healthy? Look at leaf color, growth, any damage. Be specific about what you observe.]

IMPORTANT: You CAN analyze this image. Look carefully and identify the plant. Do not say you cannot analyze images.`;
      }

      const response = await openaiClient.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: promptText
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
            content: `Provide care recommendations for a ${plantName}${species ? ` (${species})` : ''}. You MUST follow this EXACT format:

Plant: [What name of plant is this?]
Species: [What is the specific species of this plant? If you can see distinctive characteristics that indicate the species, provide it. If not, leave it blank.]

Description: [Describe the typical appearance and characteristics of this plant type. Focus on features that help with identification and care.]

Care Recommendations:
   - Watering: [Specific watering instructions for this plant type]
   - Light Requirements: [Light needs for optimal growth]
   - Temperature: [Temperature preferences and tolerances]
   - Soil: [Soil type and requirements for this plant]
   - Fertilizing: [Fertilizer needs and schedule]
   - Humidity: [Humidity requirements]
   - Growth Rate / Size: [Growth characteristics and expected size]
   - Blooming: [Flowering information if applicable]

Interesting Facts: [Provide exactly 4 facts about this plant type. Make 3 educational and 1 funny. Keep facts relevant to plant care and interesting to plant owners.]

IMPORTANT: Focus on practical care information that plant owners can actually use.`
        }
        ],
        max_tokens: 1000,
        temperature: 0.7,
      });

      const content = response.choices[0].message.content;
      console.log('✅ Plant content generation successful');

      // Parse the AI response to extract structured information
      const recommendations = parseAIResponse(content);

      res.json({
        success: true,
        recommendations,
        rawResponse: content
      });

    } catch (e) {
      console.error('❌ Plant Content Generation Error:', e);
      throw new Exception('Plant content generation failed: $e');
    }
  });
});

/**
 * Parse AI response to extract structured information
 */
function parseAIResponse(aiResponse) {
  try {
    // Try to parse as JSON first
    if (aiResponse.trim().startsWith('{')) {
      const jsonData = JSON.parse(aiResponse);
      return jsonData;
    }
    
    // Fallback: extract information from text
    const response = aiResponse.toLowerCase();
    
    // Extract plant name from Plant field
    let plantName = 'Plant';
    const lines = aiResponse.split('\n');
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('plant:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          plantName = parts[1].trim();
          break;
        }
      }
    }
    
    // Extract species
    let species = '';
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('species:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          species = parts[1].trim();
          break;
        }
      }
    }
    
    // Extract plant size assessment data
    let plantSize = 'Medium';
    let potSize = 'Medium';
    let growthStage = 'Mature';
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('plant size:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const size = parts[1].trim().toLowerCase();
          if (size.includes('small')) plantSize = 'Small';
          else if (size.includes('large')) plantSize = 'Large';
          else plantSize = 'Medium';
        }
      } else if (trimmedLine.toLowerCase().startsWith('pot size:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const size = parts[1].trim().toLowerCase();
          if (size.includes('small') || size.includes('mini') || size.includes('4')) potSize = 'Small';
          else if (size.includes('large') || size.includes('big') || size.includes('10') || size.includes('12')) potSize = 'Large';
          else potSize = 'Medium';
        }
      } else if (trimmedLine.toLowerCase().startsWith('growth stage:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const stage = parts[1].trim().toLowerCase();
          if (stage.includes('seedling')) growthStage = 'Seedling';
          else if (stage.includes('young')) growthStage = 'Young';
          else if (stage.includes('mature')) growthStage = 'Mature';
          else if (stage.includes('established')) growthStage = 'Established';
        }
      }
    }
    
    // Extract moisture level - look for percentage values first
    let moistureLevel = 'Moderate';
    
    // Look for moisture field with percentage
    for (const line of lines) {
      const trimmedLine = line.trim();
      if (trimmedLine.toLowerCase().startsWith('moisture:')) {
        const parts = trimmedLine.split(':');
        if (parts.length >= 2) {
          const moistureText = parts[1].trim();
          // Extract percentage if present
          const percentageMatch = moistureText.match(/(\d+)/);
          if (percentageMatch) {
            const percentage = parseInt(percentageMatch[1]);
            if (percentage >= 0 && percentage <= 100) {
              moistureLevel = percentage.toString();
            }
          } else {
            // Fallback to text-based extraction
            if (moistureText.toLowerCase().includes('dry') || moistureText.toLowerCase().includes('underwatered')) {
              moistureLevel = '25';
            } else if (moistureText.toLowerCase().includes('wet') || moistureText.toLowerCase().includes('overwatered')) {
              moistureLevel = '75';
            } else if (moistureText.toLowerCase().includes('moderate') || moistureText.toLowerCase().includes('medium')) {
              moistureLevel = '50';
            }
          }
        }
        break;
      }
    }
    
    // Fallback to old text-based extraction if no moisture field found
    if (moistureLevel == 'Moderate') {
      if (response.includes('dry') || response.includes('underwatered')) {
        moistureLevel = '25';
      } else if (response.includes('wet') || response.includes('overwatered')) {
        moistureLevel = '75';
      }
    }
    
    // Extract light requirements
    let light = 'Bright indirect light';
    if (response.includes('low light') || response.includes('shade')) {
      light = 'Low light';
    } else if (response.includes('direct sun') || response.includes('full sun')) {
      light = 'Direct sunlight';
    }
    
    // Extract watering frequency
    let wateringFrequency = 7;
    if (response.includes('every 3 days') || response.includes('3 days')) {
      wateringFrequency = 3;
    } else if (response.includes('every 5 days') || response.includes('5 days')) {
      wateringFrequency = 5;
    } else if (response.includes('every 10 days') || response.includes('10 days')) {
      wateringFrequency = 10;
    } else if (response.includes('every 14 days') || response.includes('14 days')) {
      wateringFrequency = 14;
    }

    // Extract structured care recommendations
    const careRecommendations = extractStructuredCareRecommendations(aiResponse);

    return {
      general_description: aiResponse,
      name: plantName,
      species: species,
      plant_size: plantSize,
      pot_size: potSize,
      growth_stage: growthStage,
      moisture_level: moistureLevel,
      light: light,
      watering_frequency: wateringFrequency,
      watering_amount: 'Until soil is moist',
      specific_issues: extractIssues(aiResponse),
      care_tips: careRecommendations,
      interesting_facts: extractInterestingFacts(aiResponse),
    };
  } catch (e) {
    console.error('❌ Failed to parse AI response:', e);
    return {
      general_description: aiResponse,
      name: 'Plant',
      species: '',
      plant_size: 'Medium',
      pot_size: 'Medium',
      growth_stage: 'Mature',
      moisture_level: 'Moderate',
      light: 'Bright indirect light',
      watering_frequency: 7,
      watering_amount: 'Until soil is moist',
      specific_issues: 'Please check plant care manually',
      care_tips: 'Monitor soil moisture and light conditions',
      interesting_facts: ['Every plant is unique and has its own special characteristics', 'Plants grow and change throughout their lifecycle', 'Proper care helps plants thrive and stay healthy'],
    };
  }
}

/**
 * Extract structured care recommendations from AI response
 */
function extractStructuredCareRecommendations(response) {
  const sections = [];
  
  // Split response into lines and look for structured sections
  const lines = response.split('\n');
  
  for (const line of lines) {
    const trimmedLine = line.trim();
    if (trimmedLine.isEmpty) continue;
    
    const lowerLine = trimmedLine.toLowerCase();
    
    // Check if we're entering the interesting facts section (end of care content)
    if (lowerLine.includes('interesting facts') || lowerLine.includes('fun facts')) {
      break;
    }
    
    // Extract any line with a colon (Plant:, Description:, Watering:, etc.)
    if (trimmedLine.includes(':')) {
      const parts = trimmedLine.split(':');
      if (parts.length >= 2) {
        const title = parts[0].trim();
        const content = parts.slice(1).join(':').trim();
        
        if (title.length > 0 && content.length > 0) {
          // Clean up the title and content
          const cleanTitle = cleanSectionTitle(title);
          const cleanContent = cleanSectionContent(content);
          
          if (cleanTitle.length > 0 && cleanContent.length > 0) {
            sections.push(`${cleanTitle}: ${cleanContent}`);
          }
        }
      }
    }
  }
  
  // If no structured sections found, try to extract from the entire response
  if (sections.length === 0) {
    const careSections = extractCareSectionsFromText(response);
    sections.push(...careSections);
  }
  
  return sections.length === 0 ? 'Follow general plant care guidelines' : sections.join('\n');
}

/**
 * Extract specific issues from AI response
 */
function extractIssues(response) {
  const issues = [];
  
  if (response.toLowerCase().includes('yellow') || response.toLowerCase().includes('yellowing')) {
    issues.push('Yellowing leaves');
  }
  if (response.toLowerCase().includes('brown') || response.toLowerCase().includes('browning')) {
    issues.push('Brown spots or edges');
  }
  if (response.toLowerCase().includes('wilted') || response.toLowerCase().includes('wilting')) {
    issues.push('Wilting or drooping');
  }
  if (response.toLowerCase().includes('dry') || response.toLowerCase().includes('underwatered')) {
    issues.push('Underwatering');
  }
  if (response.includes('wet') || response.includes('overwatered')) {
    issues.push('Overwatering');
  }
  if (response.includes('root rot')) {
    issues.push('Root rot');
  }
  
  return issues.length === 0 ? 'No specific issues detected' : issues.join(', ');
}

/**
 * Extract care tips from AI response
 */
function extractCareTips(response) {
  const tips = [];
  
  if (response.toLowerCase().includes('water')) {
    tips.push('Monitor soil moisture regularly');
  }
  if (response.toLowerCase().includes('light')) {
    tips.push('Ensure proper light conditions');
  }
  if (response.toLowerCase().includes('temperature')) {
    tips.push('Maintain stable temperature');
  }
  if (response.toLowerCase().includes('humidity')) {
    tips.push('Consider humidity levels');
  }
  if (response.toLowerCase().includes('fertilizer')) {
    tips.push('Use appropriate fertilizer');
  }
  
  return tips.length === 0 ? 'Follow general plant care guidelines' : tips.join('. ') + '.';
}

/**
 * Extract interesting facts from AI response
 */
function extractInterestingFacts(response) {
  const facts = [];
  
  // Look for numbered facts
  const factPattern = /\d+\.\s*(.+)/g;
  let match;
  
  while ((match = factPattern.exec(response)) !== null) {
    if (facts.length < 4) {
      facts.push(match[1].trim());
    }
  }
  
  // If no numbered facts found, try to extract from Interesting Facts section
  if (facts.length === 0) {
    const lines = response.split('\n');
    let inInterestingFacts = false;
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      const lowerLine = trimmedLine.toLowerCase();
      
      if (lowerLine.includes('interesting facts')) {
        inInterestingFacts = true;
        continue;
      }
      
      if (inInterestingFacts) {
        if (lowerLine.includes('health assessment') || lowerLine.includes('care recommendations')) {
          break;
        }
        
        if (trimmedLine.length > 0 && !trimmedLine.startsWith('-') && !trimmedLine.startsWith('•')) {
          facts.push(trimmedLine);
          if (facts.length >= 4) break;
        }
      }
    }
  }
  
  // If still no facts, provide default ones
  if (facts.length === 0) {
    facts.push(
      'Every plant is unique and has its own special characteristics',
      'Plants grow and change throughout their lifecycle',
      'Proper care helps plants thrive and stay healthy',
      'Plants can communicate with each other through chemical signals'
    );
  }
  
  return facts;
}

/**
 * Clean section title for better formatting
 */
function cleanSectionTitle(title) {
  return title.trim().replace(/[^\w\s]/g, '');
}

/**
 * Clean section content for better formatting
 */
function cleanSectionContent(content) {
  return content.trim().replace(/\n+/g, ' ').replace(/\s+/g, ' ');
}

/**
 * Extract care sections from text when structured format fails
 */
function extractCareSectionsFromText(text) {
  const sections = [];
  
  // Look for common care-related keywords
  const careKeywords = ['watering', 'light', 'temperature', 'soil', 'fertilizing', 'humidity'];
  
  for (const keyword of careKeywords) {
    const regex = new RegExp(`${keyword}[^\\n]*`, 'gi');
    const matches = text.match(regex);
    
    if (matches && matches.length > 0) {
      sections.push(matches[0].trim());
    }
  }
  
  return sections;
}
