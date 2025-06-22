<?php

namespace App\Controller;

use App\Entity\Event;
use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use OpenApi\Attributes as OA;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\Security\Core\User\UserInterface;

#[Route('/api/events')]
#[OA\Tag(name: 'Event')]
class EventController extends AbstractController
{
    #[OA\Get(
        summary: 'List all public events',
        description: 'Return all events that are published (state = "published")',
        responses: [
            new OA\Response(response: 200, description: 'List of published events'),
        ]
    )]
    #[Route('', name: 'api_events_list', methods: ['GET'])]
    public function list(EntityManagerInterface $em): JsonResponse
    {
        // Supposons qu'on ne veut retourner que les events publiés (state = "published")
        $events = $em->getRepository(Event::class)->findBy(['state' => 'published']);
        return $this->json($events, 200, [], ['groups' => 'event:read']);
    }

    #[OA\Get(
        summary: "List events for the current organizer",
        security: [["bearerAuth" => []]],
        responses: [
            new OA\Response(response: 200, description: "List of events for the current organizer"),
            new OA\Response(response: 401, description: "Unauthorized"),
            new OA\Response(response: 404, description: "No events found"),
        ]
    )]
    #[Route('/my', name: 'api_events_my', methods: ['GET'])]
    public function listMyEvents(EntityManagerInterface $em, UserInterface $user): JsonResponse
    {
        $this->denyAccessUnlessGranted('ROLE_ORGANIZER');

        $events = $em->getRepository(Event::class)->findBy(['organizer' => $user->getId()]);

        if (!$events) {
            return $this->json(['error' => 'No events found for this organizer'], 404);
        }

        return $this->json($events, 200, [], ['groups' => 'event:read']);
    }

    #[OA\Get(
        summary: 'Get a single event by ID',
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(response: 200, description: 'Event details'),
            new OA\Response(response: 404, description: 'Event not found'),
        ]
    )]
    #[Route('/{id}', name: 'api_events_show', methods: ['GET'])]
    public function show(int $id, EntityManagerInterface $em): JsonResponse
    {
        $event = $em->getRepository(Event::class)->find($id);
        if (!$event) {
            return $this->json(['error' => 'Event not found'], 404);
        }
        // Optionnel: ne montrer que les events publics, sauf si admin ou organisateur
        if ($event->getState() !== 'published') {
            $user = $this->getUser();
            if (!$user || (!$this->isGranted('ROLE_ADMIN') && $event->getOrganizer()->getId() !== $user->getId())) {
                return $this->json(['error' => 'Access denied'], 403);
            }
        }
        return $this->json($event, 200, [], ['groups' => 'event:read']);
    }

    #[OA\Post(
        summary: 'Create a new event',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['title', 'date', 'state'],
                properties: [
                    new OA\Property(property: 'title', type: 'string'),
                    new OA\Property(property: 'description', type: 'string'),
                    new OA\Property(property: 'city', type: 'string'),
                    new OA\Property(property: 'address', type: 'string'),
                    new OA\Property(property: 'date', type: 'string', format: 'date-time'),
                    new OA\Property(property: 'maxCapacity', type: 'integer'),
                    new OA\Property(property: 'image', type: 'string'),
                    new OA\Property(property: 'state', type: 'string'),
                    new OA\Property(property: 'price', type: 'number', format: 'float'),
                ]
            )
        ),
        responses: [
            new OA\Response(response: 201, description: 'Event created'),
            new OA\Response(response: 400, description: 'Invalid input'),
            new OA\Response(response: 403, description: 'Access denied'),
        ]
    )]
    #[Route('', name: 'api_events_create', methods: ['POST'])]
    public function create(Request $request, EntityManagerInterface $em): JsonResponse
    {
        $this->denyAccessUnlessGranted('ROLE_ORGANIZER');
        /** @var User $user */
        $user = $this->getUser();

        $data = json_decode($request->getContent(), true);

        if (empty($data['title']) || empty($data['date']) || empty($data['state'])) {
            return $this->json(['error' => 'Missing required fields (title, date, state)'], 400);
        }

        try {
            $date = new \DateTime($data['date']);
        } catch (\Exception $e) {
            return $this->json(['error' => 'Invalid date format'], 400);
        }

        $event = new Event();
        $event->setTitle($data['title']);
        $event->setDescription($data['description'] ?? null);
        $event->setCity($data['city'] ?? null);
        $event->setAddress($data['address'] ?? null);
        $event->setDate($date);
        $event->setState($data['state']);
        $event->setMaxCapacity(isset($data['maxCapacity']) ? intval($data['maxCapacity']) : null);
        $event->setImage($data['image'] ?? null);
        $event->setPrice(floatval($data['price'] ?? 0.0));
        $event->setOrganizer($user);

        $em->persist($event);
        $em->flush();

        return $this->json($event, 201, [], ['groups' => 'event:read']);
    }

    #[OA\Put(
        summary: 'Update an event',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'title', type: 'string'),
                    new OA\Property(property: 'description', type: 'string'),
                    new OA\Property(property: 'city', type: 'string'),
                    new OA\Property(property: 'address', type: 'string'),
                    new OA\Property(property: 'date', type: 'string', format: 'date-time'),
                    new OA\Property(property: 'maxCapacity', type: 'integer'),
                    new OA\Property(property: 'image', type: 'string'),
                    new OA\Property(property: 'state', type: 'string'),
                    new OA\Property(property: 'price', type: 'number', format: 'float'),
                ]
            )
        ),
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(response: 200, description: 'Event updated'),
            new OA\Response(response: 400, description: 'Invalid input'),
            new OA\Response(response: 403, description: 'Access denied'),
            new OA\Response(response: 404, description: 'Event not found'),
        ]
    )]
    #[Route('/{id}', name: 'api_events_update', methods: ['PUT'])]
    public function update(int $id, Request $request, EntityManagerInterface $em): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();

        $event = $em->getRepository(Event::class)->find($id);

        if (!$event) {
            return $this->json(['error' => 'Event not found'], 404);
        }

        if (!($this->isGranted('ROLE_ADMIN') || $event->getOrganizer()->getId() === $user->getId())) {
            return $this->json(['error' => 'Access denied'], 403);
        }

        $data = json_decode($request->getContent(), true);

        if (isset($data['date'])) {
            try {
                $date = new \DateTime($data['date']);
                $event->setDate($date);
            } catch (\Exception $e) {
                return $this->json(['error' => 'Invalid date format'], 400);
            }
        }

        if (isset($data['title'])) {
            $event->setTitle($data['title']);
        }
        if (isset($data['description'])) {
            $event->setDescription($data['description']);
        }
        if (isset($data['city'])) {
            $event->setCity($data['city']);
        }
        if (isset($data['address'])) {
            $event->setAddress($data['address']);
        }
        if (isset($data['maxCapacity'])) {
            $event->setMaxCapacity(intval($data['maxCapacity']));
        }
        if (isset($data['image'])) {
            $event->setImage($data['image']);
        }
        if (isset($data['state'])) {
            $event->setState($data['state']);
        }
        if (isset($data['price'])) {
            $event->setPrice(floatval($data['price']));
        }

        $em->flush();

        return $this->json($event, 200, [], ['groups' => 'event:read']);
    }

    #[OA\Delete(
        summary: 'Delete an event',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(response: 204, description: 'Event deleted'),
            new OA\Response(response: 403, description: 'Access denied'),
            new OA\Response(response: 404, description: 'Event not found'),
        ]
    )]
    #[Route('/{id}', name: 'api_events_delete', methods: ['DELETE'])]
    public function delete(int $id, EntityManagerInterface $em): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();
        $event = $em->getRepository(Event::class)->find($id);

        if (!$event) {
            return $this->json(['error' => 'Event not found'], 404);
        }

        if (!($this->isGranted('ROLE_ADMIN') || $event->getOrganizer()->getId() === $user->getId())) {
            return $this->json(['error' => 'Access denied'], 403);
        }

        $em->remove($event);
        $em->flush();

        return $this->json(null, 204);
    }

    #[OA\Get(
        summary: 'Search events by filters (public)',
        parameters: [
            new OA\Parameter(name: 'city', in: 'query', schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'state', in: 'query', schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'dateFrom', in: 'query', schema: new OA\Schema(type: 'string', format: 'date-time')),
            new OA\Parameter(name: 'dateTo', in: 'query', schema: new OA\Schema(type: 'string', format: 'date-time')),
        ],
        responses: [
            new OA\Response(response: 200, description: 'Filtered list of events'),
        ]
    )]
    #[Route('/search', name: 'api_events_search', methods: ['GET'])]
    public function search(Request $request, EntityManagerInterface $em): JsonResponse
    {
        $city = $request->query->get('city');
        $state = $request->query->get('state');
        $dateFrom = $request->query->get('dateFrom');
        $dateTo = $request->query->get('dateTo');

        $qb = $em->getRepository(Event::class)->createQueryBuilder('e');

        // On filtre sur les events publics uniquement (state = published) par défaut
        $qb->where('e.state = :statePublic')->setParameter('statePublic', 'published');

        if ($city) {
            $qb->andWhere('e.city LIKE :city')->setParameter('city', '%'.$city.'%');
        }
        if ($state) {
            $qb->andWhere('e.state = :state')->setParameter('state', $state);
        }
        if ($dateFrom) {
            try {
                $dateFromObj = new \DateTime($dateFrom);
                $qb->andWhere('e.date >= :dateFrom')->setParameter('dateFrom', $dateFromObj);
            } catch (\Exception $e) {
                return $this->json(['error' => 'Invalid dateFrom format'], 400);
            }
        }
        if ($dateTo) {
            try {
                $dateToObj = new \DateTime($dateTo);
                $qb->andWhere('e.date <= :dateTo')->setParameter('dateTo', $dateToObj);
            } catch (\Exception $e) {
                return $this->json(['error' => 'Invalid dateTo format'], 400);
            }
        }

        $events = $qb->getQuery()->getResult();

        return $this->json($events, 200, [], ['groups' => 'event:read']);
    }
}
