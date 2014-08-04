---
layout: post
title: Auto-complétion dans la ligne de commande pour Symfony2
tags:
- auto-complétion
- bash
- Symfony2
- zsh
status: publish
type: post
published: true
---

Lors de mon stage qui se déroule actuellement, pour un confort personnel non négligeable, j'ai décidé de voir du coté
de l'auto-complétion pour pouvoir compléter mes commandes Symfony2 suivant les bundles que j'utilise. Il existe en 
fait deux moyens.

Soit on passe par les préférences bashrc (~/.bashrc) ou équivalent (~/.zshrc, ...), et on y ajoute le fichier 
[symfony2-autcomplete](https://github.com/knplabs/symfony2-autocomplete/blob/master/symfony2-autocomplete.bash") par
knp-labs, et si on utilise [zsh](http://www.zsh.org/) et [oh my zsh](https://github.com/robbyrussell/oh-my-zsh/wiki/),
l'action du plugin Symfony2, fourni de base dans le projet vous suffira.

Sinon, vous pourrez toujours faire un tour du coté des bundles d'auto-complétion, offrant une interface web, type 
[CoreSphere/ConsoleBundle](https://github.com/CoreSphere/ConsoleBundle) par exemple. :)</p>
