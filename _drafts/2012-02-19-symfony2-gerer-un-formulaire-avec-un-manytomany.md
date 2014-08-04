---
layout: post
title: ! 'Symfony2 : Gérer un formulaire avec un ManyToMany'
tags:
- Doctrine2
- ManyToMany
- PFE
- Symfony2
status: publish
type: post
published: true
---
Hello,
Je vais aborder ici un point qui n'est pas tellement... abordé dans la documentation de Symfony2, ou bien même celle de Doctrine2.

Lors de mon projet de fin d'études (affectueusement nommé P.F.E), qui consistait à rédiger une sorte de tutoriel pour Sf2, j'ai été bloqué sur une relation ManyToMany. En éditant une entité, sur laquelle je souhaitais apposer un système de Tags. Sachant que ces tags n'ont pas réellement d'attributs, ce n'était donc pas une relation "OneToMany - ManyToOne" avec une entité tampon, mais bien une relation ManyToMany.

-- view more --

Je souhaitais donc pouvoir...

- Ajouter un couple de tags **existant** (donc, création d'une nouvelle **relation** entre *le tag et l'entité*)
- Ajouter un nouveau tag
- Supprimer une relation entre un tag et une entité

Donc OK, faire un traitement basique peut très bien convenir aux deux derniers points, à condition qu'on puisse se démerder pour avoir ce qu'on veut (à savoir un nouveau champ texte avec `property_path` à false dans le formulaire, un système pour gérer le front-end de l'ajout / suppression de tags, .. etc). En essayant de faire le keke (sinon c'est pas drôle ! ... Bien que ce soit casse-couilles), je me suis heurté à quelques problèmes que voici...

- Lors de l'ajout d'un nouveau tag, OK pas de problèmes, celui-ci est bien enregistré dans la BDD, et sa liaison est bien effectuée avec l'entité propriétaire. Donc OK, ça marche.g
- Lors de la suppression de la relation d'un tag... Il faut déjà sortir un système maison pour pas carrément **supprimer le tag**. Mais ça peut facilement s'éviter. Faire une liste de type `<select>` multiple peut être une solution.
- Mais, lors de l'ajout d'un tag existant à la liste des tags déjà répertoriés (disons j'ai un tag A, B, C sur mon entité ; je souhaite lui ajouter le tag "D" et "A" par exemple), un bug assez gênant se posait : je me retrouvais ainsi avec un **nouveau **tag "A", un nouveau "D"... !g

C'est à dire, dans ma base de données, j'avais alors...

```
// -- table des tags
1 - Tag A
2 - Tag B
3 - Tag C
4 - Tag D
5 - Tag D
6 - Tag A

// -- liaison avec une entité (disons l'entité 1) : idtag - identité
1 - 1
2 - 1
3 - 1
5 - 1
6 - 1
```

Vous voyez le problème ? Ce n'est pas l'actuel objet tag sélectionné qui est créé, mais un nouveau ! Ce n'était donc pas vraiment le comportement désiré, je pense que vous serez d'accords... Alors que je validais le tutoriel de winzou sur [Symfony2](http://www.siteduzero.com/tutoriel-3-517569-symfony2-un-tutoriel-pour-debuter-avec-le-framework-symfony2.html), j'en ai profité pour lui demander un peu conseil sur ce point là, puisque je m'occupais, en même temps, de la partie Doctrine2 de son tuto. Et, en cherchant un peu, nous avons trouvé la solution.
Il fallait en fait manipuler la `Collection` renvoyée par le formulaire (une collection de `Tag`), et faire un filtre dessus. En effet, à chaque ajout, l'id était à `null`... Et comme le champ du tag n'était pas unique (s'il l'était, ça aurait alors posé problème), il se disait que c'en était un nouveau ! D'où la duplication. Une fois le problème identifié, il fallait faire, comme je le disais donc, faire un filtre sur le Repository des tags, pour filtrer la collection et remplacer les éléments si besoin.

```php
<?php
public function filter(Collection $tags) {
  // get the tag names that were added in the collection
  $names = array();
  $flatTags = array();

  foreach ($tags->toArray() as $k => $tag) {
    if (in_array($tag->getContent(), $flatTags)) {
      $tags->remove($k);
      continue;
    }

    $flatTags[] = $tag->getContent();

    if ($tag->getId() === null) {
      $names[$k] = $tag->getContent();
    }
  }

  // all tags already exist...
  if (!$names) {
    return;
  }

  $qb = $this->createQueryBuilder('t');
  $tagsInDB = $qb->where($qb->expr()->in('t.content', $names))
                 ->getQuery()
                 ->getResult();

  // -- Replacing the tags in the array...
  foreach ($tagsInDB as $tag) {
    $tags->remove(array_search($tag->getContent(), $names));
    $tags->add($tag);
  }
}
```

Et, dans le traitement du formulaire, penser à appeler cette méthode avant de persister les tags :

```php
<?php
// ....
if ($form->isValid()) {
  $em = $this->getDoctrine()->getEntityManager();

  // -- filtering tags
  $this->getDoctrine()->getRepository('MyBundle:Tag')->filter($entity->getTags());

  foreach ($entity->getTags() as $tag) {
    $em->persist($tag);
  }

  // ...
  $em->persist($entity);
  $em->flush();
}

// ...
```

Problem Solved ! :)
