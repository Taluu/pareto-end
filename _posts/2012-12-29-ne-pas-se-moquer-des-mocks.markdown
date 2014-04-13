---
layout: post
title: Ne pas se moquer des mocks !
categories:
- Labo
tags:
- Behat
- Doctrine
- Mock
- PHPUnit
- Qualité
- Symfony
- Traits
status: publish
type: post
published: true
---
Mon travail en tant que développeur qualité a pour tâche principale de m'assurer que les produits de l'entreprise
(enfin, *le* produit dans le cas de mon entreprise) soient fonctionnels et présentent un gage de qualité. OK.

Pour s'assurer que ce soit bien le cas, et que le tout tourne de façon correcte, on dispose d'outils tels des tests
unitaires et des tests fonctionnels (et probablement d'autres à venir, qui dépendront des besoins manifestés). Ayant
fini de dessiner une première architecture de tests fonctionnels à l'aide de Behat, mon travail du moment est d'épurer
les tests PHPUnit pour qu'ils puissent fonctionner en "standalone", c'est à dire de façon complètement autonome et de
faire ce qu'ils ont à faire : tester réellement les modules de façon unitaire.

-- view more --

Avant mon arrivée, ces tests faisaient une couche fonctionnelle (maintenant plus ou moins assurée par Behat), en se
connectant à une base de données. Qu'il faut remettre à zéro à chaque lancement de la test suite. Ceci n'est pas
vraiment l'optique d'une suite de tests unitaires : celle-ci doit être complètement indépendante de l'environnement
dans laquelle elle est lancée. On test ce qu'on a à tester, et le reste, on est censé l'émuler.

Le truc, c'est que des fois, ces modules qu'on doit tester doivent récupérer des données issues d'une base de donnée.
Ou d'autres dépendances, par exemple en Symfony un accès à la couche de la gestion de sécurité. Mais c'est lourd de tout
charger, spécialement si on fonctionne de manière unitaire, c'est à dire que chaque tests puissent se lancer
indépendamment les uns des autres, en remettant à zéro tout se qui s'est passé auparavant. Pour cela, PHPUnit offre un
outil assez puissant : *les Mocks* (ou "bouchons", comme cela est traduit de façon assez moche en français...). On
indique qu'on veut mocker une classe, une interface, mais toutes les méthodes, sauf mention contraire, renverront `null`.
Juste pour servir à établir des dépendances.

OK, pourquoi pas. Mais des fois, ces mocks doivent avoir un certain comportement pour que le service fonctionne. Le
meilleur comportement que j'ai en tête, c'est celui de la base de données. Il s'agit en fait de l'émuler, sans pour
autant stocker des données de façon physique. Quand on utilise un ORM, c'est pas si facile que de faire "juste un simple
mock". Il faut essayer de stocker les données quelque part, les récupérer comme on le fait normalement (par des
repositories si on utilise Doctrine par exemple), ... En plus, avec les 
[traits, introduits avec PHP 5.4](http://fr.php.net/traits), la tâche est un peu simplifiée, qui permet d'utiliser ce
genre d'opérations avec un simple `use MockEntityManager`. Et zou, on a accès à l'`EntityManager` (ou plutôt une partie
intéressante de celui-ci, émulée bien évidemment), à une mini gestion de `Repository`, d'entités, ...

{% gist 4407655 MockEntityManager.php %}

Ce qui en fait une sorte d'ORM, sans l'être non plus, car sans avoir tout le bouzin embarqué avec, ou même *la*
fonctionnalité d'un ORM : la persistence des données. Alors qu'habituellement, ces données sont persistées d'une manière
ou d'une autre par le biais de votre SGBD favori, dans le cas d'un mock, vu qu'on ne veut juste les avoir que la durée
du tests, on peut faire fi de cet aspect, et se contenter de les mettre quelque part en mémoire. C'est un peu le but de
l'outil mock que j'ai en place. Je vous laisse essayer de jouer avec. :)

Si vous explorez un peu le gist, outre le fichier du mock de l'entity manager, j'ai également créé un mock pour le
`SecurityContext` de Symfony, qui lui reste beaucoup plus simple que celui de l'`EntityManager`.

Have fun. :)
