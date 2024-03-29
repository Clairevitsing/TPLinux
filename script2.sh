#!/bin/bash

if [ "$1" = "user" ]; then
    # Si le premier argument est "user", créer un nouvel utilisateur avec le nom et le mot de passe spécifiés
    username="$2"
    password="$3"
    
    echo "Nom d'utilisateur : $username" 
    echo "Mot de passe : $password"
    
    # Création de l'utilisateur
    useradd -m "$username"
    
    # Définition du mot de passe de l'utilisateur
    echo "$username:$password" | chpasswd
    
    echo "Utilisateur créé : $username"
    echo "Mot de passe enregistré : $password"
elif [ "$1" = "install" ]; then
    # Si le premier argument est "install", mettre à jour les référentiels et installer nginx
    apt update
    apt upgrade
    apt install -y nginx crul
    echo "Nginx et curl installé avec succès."
else
    echo "Argument invalide. Utilisation :"
    echo "Pour créer un utilisateur : ./script2 user nom_utilisateur mot_de_passe"
    echo "Pour installer nginx : ./script2 install"
fi

