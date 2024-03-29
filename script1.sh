#!/bin/bash

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

