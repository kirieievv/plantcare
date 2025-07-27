const mongoose = require('mongoose');

mongoose.connect('mongodb+srv://kirieiev:47235020wowa@plantcare.piygnqw.mongodb.net/?retryWrites=true&w=majority&appName=PlantCare')
.then(() => console.log('Connected to MongoDB Atlas'))
.catch((err) => console.error('MongoDB connection error:', err));

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = 5000;

app.use(cors());
app.use(bodyParser.json());

// User schema with auto-incrementing userId
const userSchema = new mongoose.Schema({
  userId: { type: Number, unique: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
});
const User = mongoose.model('User', userSchema);

// Plant schema with auto-incrementing plant_id per user (now per email)
const plantSchema = new mongoose.Schema({
  email: { type: String, required: true },
  plant_id: { type: Number, required: true },
  name: { type: String, required: true },
  photo: { type: String, required: true },
});
plantSchema.index({ email: 1, plant_id: 1 }, { unique: true });
const Plant = mongoose.model('Plant', plantSchema);

// Helper to get next userId
async function getNextUserId() {
  const lastUser = await User.findOne().sort({ userId: -1 });
  return lastUser ? lastUser.userId + 1 : 1;
}

// Helper to get next plant_id for a user (by email)
async function getNextPlantId(email) {
  const lastPlant = await Plant.findOne({ email }).sort({ plant_id: -1 });
  return lastPlant ? lastPlant.plant_id + 1 : 1;
}

app.get('/api/ping', (req, res) => {
  res.json({ message: 'pong' });
});

// Registration endpoint
app.post('/api/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required.' });
  }
  const existing = await User.findOne({ email });
  if (existing) {
    return res.status(409).json({ error: 'User already exists.' });
  }
  const userId = await getNextUserId();
  const user = new User({ userId, email, password });
  await user.save();
  console.log('Registered user:', user);
  res.json({ message: 'Registration successful.', userId });
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email, password });
  console.log('Login user:', user);
  if (user) {
    res.json({ message: 'Login successful.', email, userId: user.userId });
  } else {
    res.status(401).json({ error: 'Invalid credentials.' });
  }
});

// Get all plants for a user (by email)
app.get('/api/plants/:email', async (req, res) => {
  const email = decodeURIComponent(req.params.email);
  const plants = await Plant.find({ email });
  res.json(plants);
});

// Add a new plant for a user (by email)
app.post('/api/plants/:email', async (req, res) => {
  const email = decodeURIComponent(req.params.email);
  const { name, photo } = req.body;
  if (!name || !photo) {
    return res.status(400).json({ error: 'Name and photo are required.' });
  }
  const plant_id = await getNextPlantId(email);
  const plant = new Plant({ email, plant_id, name, photo });
  await plant.save();
  res.json({ message: 'Plant added.', plant });
});

// Update a plant for a user (by email)
app.put('/api/plants/:email/:plant_id', async (req, res) => {
  const email = decodeURIComponent(req.params.email);
  const plant_id = parseInt(req.params.plant_id, 10);
  const { name, photo } = req.body;
  const plant = await Plant.findOne({ email, plant_id });
  if (!plant) {
    return res.status(404).json({ error: 'Plant not found.' });
  }
  if (name) plant.name = name;
  if (photo) plant.photo = photo;
  await plant.save();
  res.json({ message: 'Plant updated.', plant });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
}); 