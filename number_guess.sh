#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

$PSQL "CREATE TABLE IF NOT EXISTS users (
  username VARCHAR(22) PRIMARY KEY,
  games_played INTEGER NOT NULL DEFAULT 0,
  best_game INTEGER
);" >/dev/null

echo "Enter your username:"
read -r username

escaped_username=$(printf '%s' "$username" | sed "s/'/''/g")
user_stats=$($PSQL "SELECT games_played || '|' || COALESCE(best_game::text, '') FROM users WHERE username = '$escaped_username';")
if [[ -z $user_stats ]]; then
  $PSQL "INSERT INTO users (username) VALUES ('$escaped_username');" >/dev/null
  echo "Welcome, $username! It looks like this is your first time here."
else
  games_played=${user_stats%%|*}
  best_game=${user_stats#*|}
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

secret_number=$(( RANDOM % 1000 + 1 ))
guess_count=0

echo "Guess the secret number between 1 and 1000:"
while read -r guess; do
  if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_digits=${guess#-}
    guess_value=$((-10#$guess_digits))
  else
    guess_digits=${guess#+}
    guess_value=$((10#$guess_digits))
  fi
  ((guess_count++))

  if (( guess_value < secret_number )); then
    echo "It's higher than that, guess again:"
  elif (( guess_value > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $guess_count tries. The secret number was $secret_number. Nice job!"
    $PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $guess_count < best_game THEN $guess_count ELSE best_game END WHERE username = '$escaped_username';" >/dev/null
    break
  fi
done
