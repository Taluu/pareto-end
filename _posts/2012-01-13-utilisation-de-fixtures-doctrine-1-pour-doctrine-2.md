---
layout: post
title: Utilisation de fixtures Doctrine 1 pour Doctrine 2
tags:
- Doctrine
- Fixtures
- PHP
- Symfony
- YAML
status: publish
type: post
published: true
---
Etant en train de développer avec Doctrine 2 en ce moment, en adaptant un début de projet que j'avais alors fait sous
symfony 1 (et que je passe du coup en Symfony 2), j'avais fait à l'époque des fixtures en YAML pour avoir des jeux de
tests.

Seul petit problème, c'est que Doctrine 2 (et par extension, Symfony2) n'embarque plus de solution pour importer
facilement des jeux de tests, et encore moins en YAML... En fouinant un peu, j'ai trouvé l'extension Doctrine 2 
[data-fixtures](https://github.com/doctrine/data-fixtures), avec le justement nommé... 
[DoctrineFixturesBundle](https://github.com/symfony/DoctrineFixturesBundle).

Une fois le truc installé, et [un peu de doc lue](http://symfony.com/doc/current/bundles/DoctrineFixturesBundle/index.html),
le truc, c'est qu'on se retrouve avec des classes PHP pour charger les différentes données... Ce qui ne nous convient
pas, nous qui avons les fichiers YAML encore en stock. Réécrire le tout à la main ? Pwah ! Trop de boulot...

Alors j'ai réuni le bundle pré-cité, et utilisé... Le composant YAML de Symfony2. Au moins, j'ai toutes mes données (dans
un array), et je n'ai plus qu'a faire une boucle dessus pour avoir des données consistantes plutôt que des données bidons. :)

J'ai développé une classe de base pour pouvoir justement charger les fixtures, que j'étends pour chaque objet que je
veux charger, qui me donne donc une méthode pour transformer en array le contenu d'un fichier YAML. Je préviens, c'est
tout con, mais moi ça m'a servi...

```php
<?php

namespace Talus\MyBundle\DataFixtures;

use Doctrine\Common\DataFixtures\AbstractFixture,
    Doctrine\Common\DataFixtures\OrderedFixtureInterface;

use Symfony\Component\Yaml\Parser;

abstract class LoadDatasFromYamlFile extends AbstractFixture implements OrderedFixtureInterface {
    /**
     * Loads datas from a fixture file from doctrine 1
     *
     * @param string $file file name
     * @return array
     */
    final protected function loadFromFile($file) {
        $yaml = new Parser;
        return $yaml->parse(file_get_contents(__DIR__ . '/yaml/' . $file . '.yml'));
    }
}
```

Encore une fois, c'est tout con, mais je le laisse là, ça peut servir... Evidemment, pensez à changer le nom du namespace.
