<?php

namespace App\Controller;

use App\Entity\Event;
use App\Entity\EventRegistration;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use OpenApi\Attributes as OA;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api/registerEvent')]
#[OA\Tag(name: 'Event Registration')]
class RegistrationController extends AbstractController
{
    #[OA\Post(
        path: '/api/registerEvent/{id}',
        summary: 'Register the authenticated user to an event',
        parameters: [
            new OA\Parameter(
                name: 'id',
                description: 'ID of the event to register for',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'integer')
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'User registered to event successfully',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'message', type: 'string')
                    ]
                )
            ),
            new OA\Response(
                response: 400,
                description: 'User already registered',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'error', type: 'string')
                    ]
                )
            ),
            new OA\Response(
                response: 401,
                description: 'Unauthorized',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'error', type: 'string')
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: 'Event not found',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'error', type: 'string')
                    ]
                )
            ),
        ]
    )]
    #[Route('/{id}', name: 'api_register_event', methods: ['POST'])]
    public function registerToEvent(
        int $id,
        EntityManagerInterface $em
    ): JsonResponse {
        /** @var User|null $user */
        $user = $this->getUser();
        if (!$user) {
            return $this->json(['error' => 'Unauthorized'], 401);
        }

        /** @var Event|null $event */
        $event = $em->getRepository(Event::class)->find($id);
        if (!$event) {
            return $this->json(['error' => 'Event not found'], 404);
        }

        $existingRegistration = $em->getRepository(EventRegistration::class)
            ->findOneBy(['user' => $user, 'event' => $event]);

        if ($existingRegistration) {
            return $this->json(['error' => 'User already registered'], 400);
        }

        $registration = new EventRegistration();
        $registration->setUser($user);
        $registration->setEvent($event);

        $em->persist($registration);
        $em->flush();

        return $this->json(['message' => 'User registered to event successfully'], 200);
    }

    #[OA\Get(
        path: '/api/registerEvent/my',
        summary: 'Get events the authenticated user is registered to',
        responses: [
            new OA\Response(
                response: 200,
                description: 'List of registered events',
                content: new OA\JsonContent(type: 'array', items: new OA\Items(type: 'object'))
            ),
            new OA\Response(
                response: 401,
                description: 'Unauthorized',
                content: new OA\JsonContent(type: 'object', properties: [
                    new OA\Property(property: 'error', type: 'string')
                ])
            )
        ]
    )]
    #[Route('/my', name: 'api_registered_events', methods: ['GET'])]
    public function getMyRegistrations(EntityManagerInterface $em): JsonResponse
    {
        /** @var User|null $user */
        $user = $this->getUser();
        if (!$user) {
            return $this->json(['error' => 'Unauthorized'], 401);
        }

        $registrations = $em->getRepository(EventRegistration::class)->findBy(['user' => $user]);

        $events = array_map(function (EventRegistration $registration) {
            $event = $registration->getEvent();
            return [
                'id' => $event->getId(),
                'title' => $event->getTitle(),
                'description' => $event->getDescription(),
                'date' => $event->getDate()?->format('c'),
                'city' => $event->getCity(),
                'adress' => $event->getAddress()
            ];
        }, $registrations);

        return $this->json($events);
    }

    #[OA\Delete(
        path: '/api/registerEvent/{id}',
        summary: 'Unregister the authenticated user from an event',
        parameters: [
            new OA\Parameter(
                name: 'id',
                description: 'ID of the event to unregister from',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'integer')
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'User unregistered successfully',
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: 'message', type: 'string')
                    ],
                    type: 'object'
                )
            ),
            new OA\Response(
                response: 400,
                description: 'User not registered',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'error', type: 'string')
                    ]
                )
            ),
            new OA\Response(
                response: 401,
                description: 'Unauthorized',
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: 'error', type: 'string')
                    ],
                    type: 'object'
                )
            ),
            new OA\Response(
                response: 404,
                description: 'Event not found',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'error', type: 'string')
                    ]
                )
            ),
        ]
    )]
    #[Route('/{id}', name: 'api_unregister_event', methods: ['DELETE'])]
    public function unregisterFromEvent(int $id, EntityManagerInterface $em): JsonResponse
    {
        /** @var User|null $user */
        $user = $this->getUser();
        if (!$user) {
            return $this->json(['error' => 'Unauthorized'], 401);
        }

        /** @var Event|null $event */
        $event = $em->getRepository(Event::class)->find($id);
        if (!$event) {
            return $this->json(['error' => 'Event not found'], 404);
        }

        $registration = $em->getRepository(EventRegistration::class)
            ->findOneBy(['user' => $user, 'event' => $event]);

        if (!$registration) {
            return $this->json(['error' => 'User not registered'], 400);
        }

        $em->remove($registration);
        $em->flush();

        return $this->json(['message' => 'User unregistered successfully'], 200);
    }

}
