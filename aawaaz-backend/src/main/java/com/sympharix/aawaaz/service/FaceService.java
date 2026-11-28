package com.sympharix.aawaaz.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

/**
 * Talks to the self-hosted face server (`POST /embed`) to turn a captured photo into a
 * face embedding. Embeddings are L2-normalized, so cosine similarity is a plain dot product.
 * The backend owns enrolment (storing embeddings) and the 1:N match done here.
 */
@Service
public class FaceService {

    private final RestClient client;

    public FaceService(@Value("${face.base-url:http://localhost:8000}") String baseUrl) {
        this.client = RestClient.builder().baseUrl(baseUrl).build();
    }

    /**
     * Embeds a base64 image via the face server.
     * @throws ResponseStatusException 400 if no/invalid single face, 503 if the server is unreachable.
     */
    public double[] embed(String imageBase64) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> resp = client.post()
                    .uri("/embed")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("imageBase64", imageBase64))
                    .retrieve()
                    .body(Map.class);
            Object raw = resp == null ? null : resp.get("embedding");
            if (!(raw instanceof List<?> list) || list.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Face service returned no embedding");
            }
            double[] out = new double[list.size()];
            for (int i = 0; i < list.size(); i++) {
                out[i] = ((Number) list.get(i)).doubleValue();
            }
            return out;
        } catch (RestClientResponseException e) {
            // The face server responded with an error status.
            if (e.getStatusCode().is4xxClientError()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Couldn't read a single clear face — please retake the photo.");
            }
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Face service error");
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Face service unavailable");
        }
    }

    /** Cosine similarity of two L2-normalized embeddings (dot product). */
    public static double similarity(double[] a, double[] b) {
        if (a.length != b.length) {
            return -1;
        }
        double dot = 0;
        for (int i = 0; i < a.length; i++) {
            dot += a[i] * b[i];
        }
        return dot;
    }

    /** Serialize / parse an embedding as a CSV of floats (stored on the user). */
    public static String toCsv(double[] embedding) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < embedding.length; i++) {
            if (i > 0) {
                sb.append(',');
            }
            sb.append(embedding[i]);
        }
        return sb.toString();
    }

    public static double[] fromCsv(String csv) {
        String[] parts = csv.split(",");
        double[] out = new double[parts.length];
        for (int i = 0; i < parts.length; i++) {
            out[i] = Double.parseDouble(parts[i]);
        }
        return out;
    }
}
