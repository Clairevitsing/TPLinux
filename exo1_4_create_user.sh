#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo or as root."
    exit 1
fi


username="$1"
password="$2"

echo "Nom d'utilisateur : $username" 
echo "Mot de passe : $password"

createUser() {
    adduser "$username"
    echo "$username:$password" | chpasswd
    echo "Utilisateur créé : $username"
    echo "Mot de passe enregistré : $password"
}

createUser

