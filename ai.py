import nltk
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
import pandas as pd
from nltk.tokenize import word_tokenize
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load the datasets into DataFrames
books = pd.read_csv(r'D:\Final Project\Books.csv', encoding='latin-1')
events = pd.read_csv(r'D:\Final Project\Events.csv', encoding='latin-1')

@app.route('/recommendations', methods=['POST'])
def get_recommendations():
    # Parse user input from Spring Boot API
    user_input = request.json
    goal_name = user_input.get('goalName')
    goal_description = user_input.get('description')
    start_date = pd.to_datetime(user_input.get('beginDate'))  # Corrected 'startDate' to 'beginDate'
    end_date = pd.to_datetime(user_input.get('endDate'))

    # Tokenize user input
    tokens = word_tokenize(user_input['description'])

    # Extract keywords or categories using POS tagging
    tagged_words = nltk.pos_tag(tokens)
    keywords = [word for word, pos in tagged_words if pos in ['NN', 'NNS', 'NNP', 'NNPS']]  # Extract nouns

    # Filter books based on extracted keywords
    filtered_books = books[books['genre'].apply(lambda x: any(keyword.lower() in x.lower() for keyword in keywords))]

    if len(filtered_books) == 0:
        book_recommendation = {"error": "Sorry, we couldn't find any books related to your input."}
    else:
        # Sort filtered books by number of ratings in descending order
        sorted_books = filtered_books.sort_values(by='Ratings', ascending=False)

        # Get the top recommended book
        top_book = sorted_books.iloc[0]  # Assuming the first book is the one with the highest ratings

        # Prepare book recommendation
        book_recommendation = {
            "Title": top_book['Title'],
            "Author": top_book['Author'],
            "genre": top_book['genre'],
            "Ratings": int(top_book['Ratings']),  # Convert int64 to int
            "Description": top_book['Description']
        }

    # Prepare event recommendation (replace this with your event recommendation logic)
    event_recommendation = {"Event": "Sample Event", "Date": "2024-03-20"}

    # Prepare recommendation response
    recommendation_response = {
        "EventRecommendation": event_recommendation,
        "BookRecommendation": book_recommendation
    }

    return jsonify(recommendation_response), 200


if __name__ == "__main__":
    app.run(debug=True)
