# Food Assistant App

A smart, conversational food-ordering assistant featuring a sleek Flutter frontend and a Python-based Natural Language Processing (NLP) backend. 

---

## 🚀 Features

* **Sleek Mobile UI:** Interactive cart management, order tracking, and intuitive user profile screens built with Flutter.
* **Smart Voice/Text Assistant:** Powered by a local NLP engine to interpret user food preferences, meal choices (Veg/Non-Veg), and order intents.
* **Local Backend API:** Fast processing of chat messages and menu items using Python.

---

## 🛠️ Project Structure

The repository contains both the frontend application and the backend service side-by-side:

* `/lib` - Flutter frontend source code (UI screens for cart, chat, menu, profile, etc.).
* `/assets` - Application images and food item icons.
* `nlp_api.py` - Python Flask/NLP server handles message processing.

---

## 🏁 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* [Python 3.x](https://www.python.org/)

### 1. Setting up the NLP Backend
Navigate to the root directory and install the required Python dependencies (such as Flask, NLTK, or any library you are using), then run the server:

```bash
# Run the Python NLP API
python nlp_api.py