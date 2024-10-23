#!/bin/bash

# Connect to PostgreSQL
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Get username
echo "Enter your username:"
read USERNAME

# Check if username exists in database
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  # Insert new user
  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # Parse existing user info
  IFS='|' read GAMES_PLAYED BEST_GAME <<< $USER_INFO
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start game
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0
GUESS=0

while [[ $GUESS != $SECRET_NUMBER ]]
do
  read GUESS
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  # Validate input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  fi
done

# Update user statistics
if [[ -z $USER_INFO ]]
then
  # First game for new user
  UPDATE_STATS=$($PSQL "UPDATE users SET games_played = 1, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
else
  # Update existing user stats
  NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
  if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME || $BEST_GAME -eq 0 ]]
  then
    NEW_BEST_GAME=$NUMBER_OF_GUESSES
  else
    NEW_BEST_GAME=$BEST_GAME
  fi
  UPDATE_STATS=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $NEW_BEST_GAME WHERE username = '$USERNAME'")
fi

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
