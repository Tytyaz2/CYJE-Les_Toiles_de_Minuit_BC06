<?php

namespace App\Controller;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use OpenApi\Attributes as OA;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Annotation\Route;

#[Route('/api/users')]
#[OA\Tag(name: 'User')]
class UserController extends AbstractController
{
    #[OA\Post(
        summary: 'Register a new user',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'password', 'name', 'role'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'password', type: 'string', format: 'password'),
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'role', type: 'string', enum: ['ROLE_USER', 'ROLE_ORGANIZER']), // nouveau champ
                ]
            )
        ),
        responses: [
            new OA\Response(response: 201, description: 'User registered successfully'),
            new OA\Response(response: 400, description: 'Missing or invalid data'),
        ]
    )]
    #[Route('/register', name: 'api_register', methods: ['POST'])]
    public function register(
        Request $request,
        EntityManagerInterface $em,
        UserPasswordHasherInterface $passwordHasher
    ): JsonResponse {
        $data = json_decode($request->getContent(), true);

        if (empty($data['email']) || empty($data['password']) || empty($data['name']) || empty($data['role'])) {
            return $this->json(['error' => 'Missing data'], 400);
        }

        // Valider le rôle
        $validRoles = ['ROLE_USER', 'ROLE_ORGANIZER'];
        if (!in_array($data['role'], $validRoles, true)) {
            return $this->json(['error' => 'Invalid role'], 400);
        }

        $user = new User();
        $user->setEmail($data['email']);
        $user->setName($data['name']);
        $user->setRoles([$data['role']]);
        $user->setPassword($passwordHasher->hashPassword($user, $data['password']));

        $em->persist($user);
        $em->flush();

        return $this->json(['message' => 'User registered successfully'], 201);
    }


    #[OA\Post(
        summary: 'User login to get JWT token',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'password'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', example: 'user@example.com'),
                    new OA\Property(property: 'password', type: 'string', example: 'yourPassword123'),
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'JWT token returned',
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: 'token', type: 'string', example: 'eyJ0eXAiOiJKV1QiLCJhbGci...')
                    ]
                )
            ),
            new OA\Response(response: 400, description: 'Missing credentials'),
            new OA\Response(response: 401, description: 'Invalid credentials'),
        ]
    )]
    #[Route('/login', name: 'api_users_login', methods: ['POST'])]
    public function login(
        Request $request,
        EntityManagerInterface $em,
        UserPasswordHasherInterface $passwordHasher,
        JWTTokenManagerInterface $JWTManager
    ): JsonResponse {
        $data = json_decode($request->getContent(), true);

        $email = $data['email'] ?? null;
        $password = $data['password'] ?? null;

        if (!$email || !$password) {
            return $this->json(['error' => 'Email and password are required'], 400);
        }

        /** @var User|null $user */
        $user = $em->getRepository(User::class)->findOneBy(['email' => $email]);

        if (!$user || !$passwordHasher->isPasswordValid($user, $password)) {
            return $this->json(['error' => 'Invalid credentials'], 401);
        }

        $token = $JWTManager->create($user);

        return $this->json(['token' => $token]);
    }

    #[OA\Get(
        summary: 'Get authenticated user profile',
        security: [['bearerAuth' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'User profile',
            )
        ]
    )]
    #[Route('/me', name: 'api_users_me', methods: ['GET'])]
    public function me(): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();
        return $this->json($user, 200, [], ['groups' => 'user:read']);
    }

    #[OA\Get(
        summary: 'List all users (Admin only)',
        security: [['bearerAuth' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'List of users',
            )
        ]
    )]
    #[Route('', name: 'api_users_list', methods: ['GET'])]
    public function list(EntityManagerInterface $em): JsonResponse
    {
        $this->denyAccessUnlessGranted('ROLE_ADMIN');
        $users = $em->getRepository(User::class)->findAll();
        return $this->json($users, 200, [], ['groups' => 'user:read']);
    }

    #[OA\Get(
        summary: 'Get a specific user by ID (Admin only)',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'User data',
            ),
            new OA\Response(response: 404, description: 'User not found')
        ]
    )]
    #[Route('/{id}', name: 'api_users_show', methods: ['GET'])]
    public function show(int $id, EntityManagerInterface $em): JsonResponse
    {
        $this->denyAccessUnlessGranted('ROLE_ADMIN');
        $user = $em->getRepository(User::class)->find($id);
        if (!$user) {
            return $this->json(['error' => 'User not found'], 404);
        }
        return $this->json($user, 200, [], ['groups' => 'user:read:full']);
    }

    #[OA\Post(
        summary: 'Create a new user (Admin only)',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'email', type: 'string'),
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'password', type: 'string'),
                    new OA\Property(property: 'roles', type: 'array', items: new OA\Items(type: 'string'))
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'User created',
            )
        ]
    )]
    #[Route('', name: 'api_users_create', methods: ['POST'])]
    public function create(
        Request $request,
        EntityManagerInterface $em,
        UserPasswordHasherInterface $passwordHasher
    ): JsonResponse {
        $this->denyAccessUnlessGranted('ROLE_ADMIN');
        $data = json_decode($request->getContent(), true);

        $user = new User();
        $user->setEmail($data['email'] ?? '');
        $user->setName($data['name'] ?? '');
        $user->setRoles($data['roles'] ?? ['ROLE_USER']);
        $user->setPassword($passwordHasher->hashPassword($user, $data['password'] ?? 'password'));

        $em->persist($user);
        $em->flush();

        return $this->json($user, 201, [], ['groups' => 'user:read:full']);
    }

    #[OA\Delete(
        summary: 'Delete a user by ID (Admin only)',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(response: 204, description: 'User deleted'),
            new OA\Response(response: 404, description: 'User not found')
        ]
    )]
    #[Route('/{id}', name: 'api_users_delete', methods: ['DELETE'])]
    public function delete(int $id, EntityManagerInterface $em): JsonResponse
    {
        $this->denyAccessUnlessGranted('ROLE_ADMIN');
        $user = $em->getRepository(User::class)->find($id);
        if (!$user) {
            return $this->json(['error' => 'User not found'], 404);
        }

        $em->remove($user);
        $em->flush();

        return $this->json(null, 204);
    }
}
