#!/bin/bash

# Deployment script for Watering Reminders FCM feature
# This script deploys all necessary components for the notification system

set -e

echo "🚀 Deploying Watering Reminders System..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Install Flutter dependencies
echo -e "${YELLOW}📦 Installing Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
echo ""

# Step 2: Deploy Cloud Functions
echo -e "${YELLOW}☁️  Deploying Cloud Functions...${NC}"
cd functions
npm install
cd ..
firebase deploy --only functions:sendWateringReminders
echo -e "${GREEN}✅ Cloud Functions deployed${NC}"
echo ""

# Step 3: Deploy Firestore indexes
echo -e "${YELLOW}📊 Deploying Firestore indexes...${NC}"
firebase deploy --only firestore:indexes
echo -e "${GREEN}✅ Firestore indexes deployed${NC}"
echo ""

# Step 4: Deploy Firestore rules
echo -e "${YELLOW}🔒 Deploying Firestore security rules...${NC}"
firebase deploy --only firestore:rules
echo -e "${GREEN}✅ Firestore rules deployed${NC}"
echo ""

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Test FCM token registration: flutter run"
echo "2. Configure notification settings in the app (Settings screen)"
echo "3. Add a plant and verify notification scheduling"
echo "4. Monitor Cloud Function logs: firebase functions:log --only sendWateringReminders"
echo ""
echo "For detailed setup instructions, see WATERING_REMINDERS_SETUP.md"


