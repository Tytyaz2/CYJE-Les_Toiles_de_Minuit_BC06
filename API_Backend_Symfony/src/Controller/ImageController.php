<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Symfony\Component\Routing\Annotation\Route;

class ImageController
{
    #[Route('/EventImage/{id}/{filename}', name: 'event_image')]
    public function getImage(int $id, string $filename): BinaryFileResponse
    {
        $filePath = 'EventImage' . '/' . $id . '/' . $filename;

        $response = new BinaryFileResponse($filePath);
        $response->headers->set('Access-Control-Allow-Origin', '*'); // ✅

        return $response;
    }

}
