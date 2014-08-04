---
layout: post
title: Ne pas se moquer des mocks !
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

```php
<?php

namespace Traits\Tests;

/**
 * Mocks the entity manager
 *
 * Provides everything in the memory, so the tests does not depend on doctrine,
 * which does a lot of stuff (maybe too much). This also allows to avoid to
 * need and modify the data in the database, even if those are for the tests.
 *
 * This mock provides the entity manager, a way to persist objets in memory
 * (and also increment an id if it can do it through a setId method), and also
 * manages repositories.
 */
trait MockEntityManager
{
    use MockWithoutConstructor;

    private $entityManager = ['init'     => false,
                              'mocks'    => [],
                              'repos'    => [],
                              'entities' => []];

    /**
     * Initializes the mocked entity manager
     */
    public function initEntityManager()
    {
        if ($this->entityManager['init']) {
            return;
        }

        $this->entityManager['mocks'] = ['em'    => $this->getMockWithoutConstructor('\Doctrine\ORM\EntityManager'),
                                         'repos' => []];

        $this->entityManager['mocks']['em']->expects($this->any())
                                           ->method('getRepository')
                                           ->will($this->returnCallback(function ($repo) {
                                                return $this->getRepository($repo);
                                            }));

        $callbackEntity = function ($method = 'persist') {
            return function ($entity) use ($method) {
                // don't even bother if it's not an object
                if (!is_object($entity)) {
                    return;
                }

                $alias = explode('\\', get_class($entity));
                $alias = lcfirst(array_pop($alias));

                if (!isset($this->entityManager['entities'][$alias])) {
                    $this->entityManager['entities'][$alias] = ['sequence' => 0,
                                                                'objects'  => []];
                }

                $found = null !== $entity->getId() 
                       ? array_search($this->getEntityByAliasAndId($alias, $entity->getId()), $this->entityManager['entities'][$alias]['objects']) 
                       : false;

                switch ($method) {
                    case 'persist':
                        if (false === $found) {
                            $found = $this->entityManager['entities'][$alias]['sequence']++;

                            if (method_exists($entity, 'setId')) {
                                $entity->setId($this->entityManager['entities'][$alias]['sequence']);
                            }
                        }

                        $this->entityManager['entities'][$alias]['objects'][$found] = $entity;
                        break;

                    case 'remove':
                        if (false !== $found) {
                            unset($this->entityManager['entities'][$alias]['objects'][$found]);
                        }

                        break;
                }
            };
        };

        $this->entityManager['mocks']['em']->expects($this->any())
                                           ->method('persist')
                                           ->will($this->returnCallback($callbackEntity('persist')));

        $this->entityManager['mocks']['em']->expects($this->any())
                                           ->method('flush')
                                           ->will($this->returnValue(null));

        $this->entityManager['mocks']['em']->expects($this->any())
                                           ->method('remove')
                                           ->will($this->returnCallback($callbackEntity('remove')));

        $this->entityManager['init'] = true;
    }

    /**
     * Get the mocked entity manager.
     *
     * Initializes it if it was not already initialized.
     */
    public function getMockedEntityManager()
    {
        $this->initEntityManager();

        return $this->entityManager['mocks']['em'];
    }

    /**
     * Add a repository to be mocked.
     *
     * It also registers an alias for this repo
     *
     * @param string $alias   Alias for this repository
     * @param string $fqcn    Class name of the repository
     * @param array  $options Options to be given to this repository. Not used yet.
     */
    public function addRepository($alias, $fqcn, array $options = [])
    {
        $this->entityManager['mocks']['repos'][$alias] = $this->getMockWithoutConstructor($fqcn);
        $this->entityManager['repos'][$alias] = ['fqcn'    => $fqcn,
                                                 'options' => $options];
    }

    /**
     * Get a repository.
     *
     * Searches first in the alias, then with the repo's classname
     *
     * @param string $repoName repo to get
     * @return null|object null if not found, the mock otherwise
     */
    public function getRepository($repoName)
    {
        // first try to load via an alias
        $repo = $this->getRepositoryByAlias($repoName);

        if (null === $repo) {
            $repo = $this->getRepositoryByClass($repoName);
        }

        return $repo;
    }

    /**
     * Gets a repository by its alias.
     *
     * @param string $alias Alias to search
     * @return null|object null if not found, the mock otherwise
     */
    public function getRepositoryByAlias($alias)
    {
        if (!isset($this->entityManager['mocks']['repos'][$alias])) {
            return null;
        }

        return $this->entityManager['mocks']['repos'][$alias];
    }

    /**
     * Gets a repository by its full classified class name.
     *
     * @param string $fqcn Class to search
     * @return null|object null if not found, the mock otherwise
     */
    public function getRepositoryByClass($fqcn)
    {
        $found = false;

        foreach ($this->entityManager['repos'] as $alias => $repo) {
            if ($fqcn === $repo['fqcn']) {
                return $this->getRepositoryByAlias($alias);
            }
        }

        return null;
    }

    /**
     * Gets an entity by its alias and its id.
     *
     * @param string $alias name of the entity, without the namespaces
     * @param mixed  $id    Id to fetch. "null" to get the last entity
     * @return object|null the entity if found, null otherwise
     */
    public function getEntityByAliasAndId($alias, $id = null)
    {
        if (!isset($this->entityManager['entities'][$alias])) {
            return null;
        }

        if (0 === count($this->entityManager['entities'][$alias]['objects'])) {
            return null;
        }

        if (null === $id) {
            $entity = end($this->entityManager['entities'][$alias]['objects']);
            reset($this->entityManager['entities'][$alias]['objects']);

            return $entity;
        }

        foreach ($this->entityManager['entities'][$alias]['objects'] as $oid => $entity) {
            if ($id === ($oid + 1) || $id === $entity->getId()) {
                return $entity;
            }
        }

        return null;
    }

    /**
     * Gets the latest entity registered for $alias.
     *
     * @param string $alias Name of the entity, without the namespaces
     * @return object|null the last entity if there is one, null otherwise
     */
    public function getEntityByAlias($alias)
    {
        return $this->getEntityByAliasAndId($alias, null);
    }

    /**
     * Gets information on all the entities.
     *
     * @return array for each entities, return the fqcn, the current sequence
     *         and the number of items
     */
    public function getAllEntities()
    {
        $tab = [];

        foreach($this->entityManager['entities'] as $alias => $entities){
            if (0 < count($entities['objects'])) {
                $tab[$alias] = ['entity'   => get_class($entities['objects'][0]),
                                'sequence' => $entities['sequence'],
                                'count'    => count($entities['objects'])];
            }
        }

        return $tab;
    }

    /**
     * Gets the entities for a given alias, or all of them if null.
     *
     * The difference with getAllEntities() is that this method returns
     * the object, instead of the information
     *
     * @return object[] ALLUVEM !
     */
    public function getEntities($alias = null)
    {
        if (null === $alias) {
            $entities = [];

            foreach ($this->entityManager['entities'] as $alias) {
                $entities += $alias['objects'];
            }

            return $entities;
        }

        if (!isset($this->entityManager['entities'][$alias])) {
            return null;
        }

        return $this->entityManager['entities'][$alias]['objects'];
    }
}
```

Ce qui en fait une sorte d'ORM, sans l'être non plus, car sans avoir tout le bouzin embarqué avec, ou même *la*
fonctionnalité d'un ORM : la persistence des données. Alors qu'habituellement, ces données sont persistées d'une manière
ou d'une autre par le biais de votre SGBD favori, dans le cas d'un mock, vu qu'on ne veut juste les avoir que la durée
du tests, on peut faire fi de cet aspect, et se contenter de les mettre quelque part en mémoire. C'est un peu le but de
l'outil mock que j'ai en place. Je vous laisse essayer de jouer avec. :)

Si [vous explorez un peu le gist](https://gist.github.com/Taluu/4407655), outre le fichier du mock de l'entity manager,
j'ai également créé un mock pour le `SecurityContext` de Symfony, qui lui reste beaucoup plus simple que celui de 
l'`EntityManager`.

Have fun. :)
