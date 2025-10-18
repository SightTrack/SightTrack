// index.mjs
const { APPSYNC_URL, APPSYNC_API_KEY, CORS_ORIGIN = "*" } = process.env;

// GraphQL query to list sightings
const LIST_SIGHTINGS = /* GraphQL */ `
  query ListSightings($limit: Int, $nextToken: String, $filter: ModelSightingFilterInput) {
    listSightings(limit: $limit, nextToken: $nextToken, filter: $filter) {
      items {
        id
        species
        photo
        latitude
        longitude
        timestamp
        description
      }
      nextToken
    }
  }
`;

// Optional: build filter from query string (e.g., species, date range, bounding box)
function buildFilter(q) {
  const f = {};
  if (q.species) f.species = { eq: q.species };

  if (q.since || q.until) {
    f.timestamp = {};
    if (q.since) f.timestamp.ge = q.since;
    if (q.until) f.timestamp.le = q.until;
  }

  // Bounding box format: bbox=minLon,minLat,maxLon,maxLat
  if (q.bbox) {
    const [minLon, minLat, maxLon, maxLat] = q.bbox.split(",").map(Number);
    f.and = [
      { latitude: { ge: minLat } },
      { latitude: { le: maxLat } },
      { longitude: { ge: minLon } },
      { longitude: { le: maxLon } },
    ];
  }

  return Object.keys(f).length ? f : undefined;
}

// Call AppSync directly using API key
async function callAppSync(query, variables) {
  const res = await fetch(APPSYNC_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": APPSYNC_API_KEY, // Public read-only key
    },
    body: JSON.stringify({ query, variables }),
  });

  const json = await res.json();
  if (json.errors) throw new Error(json.errors.map(e => e.message).join("; "));
  return json.data;
}

export const handler = async (event) => {
  try {
    const qs = event.queryStringParameters || {};
    const limit = Math.min(Number(qs.limit) || 50, 200);
    const nextToken = qs.nextToken || undefined;
    const filter = buildFilter(qs);

    const data = await callAppSync(LIST_SIGHTINGS, { limit, nextToken, filter });
    const { items, nextToken: nt } = data.listSightings;

    return {
      statusCode: 200,
      headers: {
        "content-type": "application/json",
        "access-control-allow-origin": CORS_ORIGIN, // public or restricted to your domain
        "access-control-allow-methods": "GET,OPTIONS",
        "access-control-allow-headers": "Content-Type",
        "cache-control": "public, max-age=30"
      },
      body: JSON.stringify({ items, nextToken: nt ?? null }),
    };
  } catch (e) {
    console.error(e);
    return {
      statusCode: 500,
      headers: {
        "content-type": "application/json",
        "access-control-allow-origin": CORS_ORIGIN,
      },
      body: JSON.stringify({ error: "Internal error", message: e.message }),
    };
  }
};
