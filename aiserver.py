import nltk
nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')
import pandas as pd
from nltk.tokenize import word_tokenize
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Load the dataset into a DataFrame
# Load the dataset into a DataFrame
books = pd.read_csv('D:\\Final Project\\Books.csv', encoding='latin1')
events = pd.read_csv('D:\\Final Project\\events.csv', encoding='latin1')

# Prompt user for their input
@app.route('/recommendations', methods=['POST'])
def get_recommendations():
    # Parse user input from Spring Boot API
    user_input = request.json
    goal_name = user_input.get('goalName')
    goal_description = user_input.get('description')
    start_date = pd.to_datetime(user_input.get('startDate'))
    end_date = pd.to_datetime(user_input.get('endDate'))

    # Tokenize user input
    tokens = word_tokenize(user_input['description'])  # Changed from user_input to user_input['description']

    # Extract keywords or categories using POS tagging
    tagged_words = nltk.pos_tag(tokens)
    keywords = [word for word, pos in tagged_words if pos in ['NN', 'NNS', 'NNP', 'NNPS']]  # Extract nouns

    # Filter books based on extracted keywords
    filtered_books = books[books['genre'].apply(lambda x: any(keyword.lower() in x.lower() for keyword in keywords))]

    #Filtered events based on extracted keywords
    filtered_events = events[events['domain'].apply(lambda x: any(keyword.lower() in x.lower() for keyword in keywords))]

    if len(filtered_events) == 0:
        return jsonify({"error": "Sorry, we couldn't find any events related to your input."}), 404
    else:
        # Rank the filtered events (for example, you can sort by date or any other relevant metric)
        sorted_events = filtered_events.sort_values(by='date')

        # Get the top recommended event
        top_event = sorted_events.iloc[0]  # Assuming the first event is the one most relevant

        # Prepare event recommendation response
        event_recommendation = {
            "Title": top_event['title'],
            "Date": top_event['date'],
            "Time": top_event['time'],
            "Location": top_event['location'],
            "Speaker": top_event['speaker'],
            "Event Mode": top_event['event_mode'],
            "Description": top_event['description']
        }

    if len(filtered_books) == 0:
        return jsonify({"error": "Sorry, we couldn't find any books related to your input."}), 404
    else:
        # Sort filtered books by number of ratings in descending order
        sorted_books = filtered_books.sort_values(by='Ratings', ascending=False)

        # Get the top recommended book
        top_book = sorted_books.iloc[0]  # Assuming the first book is the one with the highest ratings

        # Prepare recommendation response
        book_recommendation = {
            "Title": top_book['Title'],
            "Author": top_book['Author'],
            "Genre": top_book['genre'],
            "Ratings": top_book['Ratings'],
            "Description": top_book['Description']
        }

               # Combine book and event recommendations into a single response
        recommendation = [book_recommendation, event_recommendation]

        return jsonify(recommendation), 200

if __name__ == "__main__":
    app.run(debug=True)