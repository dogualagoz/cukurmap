/**
 * Seeds the 81 Turkish provinces: boundaries (GeoJSON, Apache-2.0,
 * github.com/alpers/Turkey-Maps-GeoJSON), TÜİK 2023 populations and
 * auto-generated genitive hashtags (#EskişehirinÇukurları).
 * Idempotent: upserts by plate code.
 */
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface ProvinceFeature {
  properties: { name: string; number: number };
  geometry: { type: string; coordinates: unknown };
}

// GeoJSON says "Afyon"; official name is Afyonkarahisar
const NAME_OVERRIDES: Record<number, string> = { 3: 'Afyonkarahisar' };

// TÜİK ADNKS 2023 (yaklaşık; lig normalizasyonu için hassasiyet kritik değil)
const POPULATIONS: Record<number, number> = {
  1: 2270727, 2: 604978, 3: 747555, 4: 511238, 5: 339529, 6: 5803482,
  7: 2696249, 8: 169543, 9: 1161702, 10: 1257590, 11: 228334, 12: 285655,
  13: 359808, 14: 324789, 15: 273799, 16: 3214571, 17: 559383, 18: 205501,
  19: 528351, 20: 1056332, 21: 1818133, 22: 419913, 23: 604411, 24: 243399,
  25: 749754, 26: 906617, 27: 2154051, 28: 461712, 29: 148539, 30: 287625,
  31: 1544640, 32: 449777, 33: 1916432, 34: 15655924, 35: 4479525, 36: 274829,
  37: 388990, 38: 1445683, 39: 377156, 40: 244519, 41: 2102907, 42: 2320241,
  43: 575674, 44: 742725, 45: 1475353, 46: 1116618, 47: 888874, 48: 1066736,
  49: 399202, 50: 315994, 51: 365419, 52: 763190, 53: 344016, 54: 1080080,
  55: 1368488, 56: 347412, 57: 229716, 58: 634924, 59: 1142451, 60: 596454,
  61: 824352, 62: 89317, 63: 2213964, 64: 375454, 65: 1127612, 66: 420699,
  67: 588510, 68: 433055, 69: 86047, 70: 260838, 71: 285744, 72: 647205,
  73: 570745, 74: 203241, 75: 92481, 76: 209738, 77: 304780, 78: 255242,
  79: 155179, 80: 557666, 81: 409865,
};

const TR_ASCII: Record<string, string> = {
  ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u',
  Ç: 'c', Ğ: 'g', I: 'i', İ: 'i', Ö: 'o', Ş: 's', Ü: 'u',
};

function slugify(name: string): string {
  return name
    .split('')
    .map((ch) => TR_ASCII[ch] ?? ch)
    .join('')
    .toLowerCase();
}

const VOWELS = 'aeıioöuüAEIİOÖUÜ';
const GENITIVE: Record<string, string> = {
  a: 'ın', ı: 'ın', e: 'in', i: 'in', o: 'un', u: 'un', ö: 'ün', ü: 'ün',
};

/** İstanbul → İstanbulunÇukurları, Adana → AdananınÇukurları */
function hashtagFor(name: string): string {
  const lastVowel = [...name.toLowerCase()]
    .reverse()
    .find((ch) => VOWELS.includes(ch));
  const suffix = GENITIVE[lastVowel ?? 'a'];
  const buffer = VOWELS.includes(name[name.length - 1]) ? 'n' : '';
  return `${name}${buffer}${suffix}Çukurları`;
}

async function main() {
  const raw = readFileSync(
    join(__dirname, 'data', 'tr-provinces.geojson'),
    'utf8',
  );
  const collection = JSON.parse(raw) as { features: ProvinceFeature[] };
  if (collection.features.length !== 81) {
    throw new Error(`Expected 81 provinces, got ${collection.features.length}`);
  }

  for (const feature of collection.features) {
    const id = feature.properties.number;
    const name = NAME_OVERRIDES[id] ?? feature.properties.name;
    const geomJson = JSON.stringify(feature.geometry);
    await prisma.$executeRaw`
      INSERT INTO provinces (id, name, slug, hashtag, population, boundary)
      VALUES (
        ${id}, ${name}, ${slugify(name)}, ${hashtagFor(name)}, ${POPULATIONS[id]},
        ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(${geomJson}), 4326))
      )
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        slug = EXCLUDED.slug,
        hashtag = EXCLUDED.hashtag,
        population = EXCLUDED.population,
        boundary = EXCLUDED.boundary
    `;
  }

  // Sanity: Kızılay/Ankara koordinatı 06 Ankara'ya düşmeli
  const hit = await prisma.$queryRaw<{ id: number }[]>`
    SELECT id FROM provinces
    WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(32.8541, 39.9208), 4326))
  `;
  if (hit[0]?.id !== 6) {
    throw new Error(`Point-in-polygon sanity check failed: ${JSON.stringify(hit)}`);
  }
  console.log('Seeded 81 provinces; ST_Contains sanity check passed.');
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (err) => {
    console.error(err);
    await prisma.$disconnect();
    process.exit(1);
  });
