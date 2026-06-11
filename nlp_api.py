from flask import Flask, request, jsonify
from flask_cors import CORS
import nltk
from nltk.stem import WordNetLemmatizer, PorterStemmer
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
import re

# Download the AI dictionary & Segmentation files the first time
nltk.download('wordnet')
nltk.download('omw-1.4')
nltk.download('punkt')      # For Text Segmentation (Tokenization)
nltk.download('punkt_tab')  # Fallback for punkt
nltk.download('stopwords')  # For Preprocessing (Stopword removal)

app = Flask(__name__)
CORS(app) 

lemmatizer = WordNetLemmatizer()
stemmer = PorterStemmer()

# Load standard English fluff words (i, me, my, the, is, etc.)
stop_words = set(stopwords.words('english'))

# Add our custom App fluff words and conversational words to the filter
custom_fluff = {
    'order', 'food', 'menu', 'suggest', 'options', 'please', 'want', 
    'like', 'would', 'show', 'give', 'today', 'yesterday', 'tomorrow', 
    'now', 'get', 'eat', 'items', 'item', 'some', 'me', 'i', 'can', 'you'
}
all_stops = stop_words.union(custom_fluff)

# 🧠 NEW: NAMED ENTITY RECOGNITION (NER) DICTIONARIES
# We teach the AI what foods belong to what categories
NON_VEG_WORDS = ['chicken', 'mutton', 'fish', 'egg', 'meat', 'beef', 'prawn', 'crab']
VEG_WORDS = ['paneer', 'mushroom', 'veg', 'vegetable', 'gobi', 'carrot', 'aloo', 'potato', 'rice', 'roti']

# -------------------------------------------------------------
# ROUTE 1: Extract Keywords from Voice Command (Existing)
# -------------------------------------------------------------
@app.route('/process_command', methods=['POST'])
def process_command():
    data = request.json
    raw_sentence = data.get('sentence', '')
    
    clean_text = re.sub(r'[^\w\s]', '', raw_sentence.lower())
    words = word_tokenize(clean_text)
    filtered_words = [w for w in words if w not in all_stops]
    core_keyword = " ".join(filtered_words)
    
    return jsonify({"status": "success", "keyword": core_keyword})

# -------------------------------------------------------------
# ROUTE 2: Analyze Dietary Restrictions (Existing)
# -------------------------------------------------------------
@app.route('/analyze', methods=['POST'])
def analyze_text():
    data = request.json
    words = data.get('words', [])
    
    results = []
    for word in words:
        safe_word = word.strip().lower()
        if not safe_word:
            continue
            
        lemma = lemmatizer.lemmatize(safe_word) 
        stem = stemmer.stem(safe_word)          
        
        results.append({
            "original": safe_word,
            "lemma": lemma,
            "stem": stem
        })
        
    return jsonify({"status": "success", "data": results})

# -------------------------------------------------------------
# 🌟 ROUTE 3: THE "REAL BRAIN" (Advanced Chatbot Pipeline) 🌟
# -------------------------------------------------------------
@app.route('/smart_chat', methods=['POST'])
def smart_chat():
    data = request.get_json()
    raw_sentence = data.get('sentence', '')
    current_day = data.get('day', '')
    diet_rules = data.get('banned_items', []) # Example: ["Non-Veg"]

    # STEP 1: TEXT PREPROCESSING (Remove punctuation)
    clean_text = re.sub(r'[^\w\s]', '', raw_sentence.lower())

    # STEP 2: SEGMENTATION (Tokenize into words)
    words = word_tokenize(clean_text)

    # STEP 3 & 4: STOPWORD REMOVAL & LEMMATIZATION
    clean_lemmas = []
    for w in words:
        if w not in all_stops and w.isalnum():
            # Lemmatize finds the root (e.g., "chickens" -> "chicken", "items" -> "item")
            lemma = lemmatizer.lemmatize(w)
            clean_lemmas.append(lemma)

    # STEP 5: NAMED ENTITY RECOGNITION (NER)
    # Check if the remaining words contain any meat or veg entities
    requested_non_veg = [word for word in clean_lemmas if word in NON_VEG_WORDS]
    requested_veg = [word for word in clean_lemmas if word in VEG_WORDS]

    # STEP 6: INTENT CLASSIFICATION & RULE ENGINE (The deep thinking)
    
    # RULE A: Did they ask for meat on a day where meat is banned?
    if requested_non_veg and "Non-Veg" in diet_rules:
        meats = ", ".join(requested_non_veg)
        return jsonify({
            "status": "blocked",
            "bot_reply": f"I see you asked for {meats}, but today is {current_day}. Your diet plan strictly prohibits meat today! 🚫🥦",
            "search_query": None
        })

    # RULE B: Did they ask for valid food entities?
    if requested_non_veg or requested_veg or clean_lemmas:
        # Join the pure, clean ingredients to search the database
        search_target = " ".join(clean_lemmas)
        return jsonify({
            "status": "allowed",
            "bot_reply": "Let me see what I can find for you...",
            "search_query": search_target
        })

    # RULE C: Fallback (They just said "hello" or confusing fluff)
    return jsonify({
        "status": "unknown",
        "bot_reply": "I heard you, but I didn't catch a specific food name. What dish would you like?",
        "search_query": None
    })

if __name__ == '__main__':
    # Keep 0.0.0.0 so your mobile app can connect!
    app.run(host='0.0.0.0', port=5000, debug=True)