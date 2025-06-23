<?php

namespace App\DataFixtures;

use App\Entity\EventRegistration;
use App\Entity\User;
use App\Entity\Event;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

class AppFixtures extends Fixture
{
    private UserPasswordHasherInterface $hasher;

    public function __construct(UserPasswordHasherInterface $hasher)
    {
        $this->hasher = $hasher;
    }

    public function load(ObjectManager $manager): void
    {
        // Création des utilisateurs
        $admin = new User();
        $admin->setEmail('admin@example.com');
        $admin->setRoles(['ROLE_ADMIN']);
        $admin->setPassword($this->hasher->hashPassword($admin, 'admin'));
        $admin->setName('admin');
        $manager->persist($admin);

        $organizer = new User();
        $organizer->setEmail('organizer@example.com');
        $organizer->setRoles(['ROLE_ORGANIZER']);
        $organizer->setPassword($this->hasher->hashPassword($organizer, 'organizer'));
        $organizer->setName('organizer');
        $manager->persist($organizer);

        $user = new User();
        $user->setEmail('user@example.com');
        $user->setRoles(['ROLE_USER']);
        $user->setPassword($this->hasher->hashPassword($user, 'user'));
        $user->setName('user');
        $manager->persist($user);

        // Création des événements
        $event1 = new Event();
        $event1->setTitle('Premier Événement');
        $event1->setDescription('Une description cool.');
        $event1->setCity('Paris');
        $event1->setAddress('10 rue de la Paix');
        $event1->setDate(new \DateTime('2025-07-01 18:00:00'));
        $event1->setState('published');
        $event1->setImage('cover.jpg');
        $event1->setMaxCapacity(2);
        $event1->setPrice(20.0);
        $event1->setOrganizer($organizer);
        $manager->persist($event1);

        $event2 = new Event();
        $event2->setTitle('Deuxième Événement');
        $event2->setDescription('Un autre événement sympa.');
        $event2->setCity('Lyon');
        $event2->setAddress('25 avenue des Lumières');
        $event2->setDate(new \DateTime('2025-08-15 14:00:00'));
        $event2->setState('draft');
        $event2->setPrice(15.0);
        $event2->setImage('cover2.jpg');
        $event2->setMaxCapacity(1);
        $event2->setOrganizer($organizer);
        $manager->persist($event2);

        $event3 = new Event();
        $event3->setTitle('Troisième Événement');
        $event3->setDescription('Un dernier événement.');
        $event3->setCity('Marseille');
        $event3->setAddress('5 boulevard du Port');
        $event3->setDate(new \DateTime('2025-09-10 20:00:00'));
        $event3->setState('published');
        $event3->setPrice(25.0);
        $event3->setImage('cover3.jpg');
        $event3->setMaxCapacity(3);
        $event3->setOrganizer($organizer);
        $manager->persist($event3);

        // Inscription de l'utilisateur 'user' à un événement publié (event1)
        $registration = new EventRegistration();
        $registration->setUser($user);
        $registration->setEvent($event1);
        $manager->persist($registration);

        $manager->flush();
    }
}
