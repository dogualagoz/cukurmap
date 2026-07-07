# CukurMap — Veri Modeli

PostgreSQL 16 + PostGIS. ORM: Prisma (geometri kolonları `Unsupported("geometry(...)")`,
kolon/index tanımları migration SQL'inde). Geo sorguları parametrik raw SQL,
repository katmanında izole.

## users
| Kolon | Tip | Not |
|---|---|---|
| id | uuid PK | |
| device_hash | text UNIQUE | SHA-256(deviceId + DEVICE_PEPPER). Ham cihaz kimliği saklanmaz (KVKK) |
| nickname | varchar(40) | Otomatik mizahi rumuz ("Çukur Avcısı #4821"), değiştirilebilir |
| is_banned | boolean default false | |
| created_at / last_seen_at | timestamptz | |

## provinces (81 il, seed ile doldurulur)
| Kolon | Tip | Not |
|---|---|---|
| id | smallint PK | Plaka kodu (1–81) |
| name / slug | text | "Eskişehir" / "eskisehir" |
| hashtag | text | "EskişehirinÇukurları" |
| population | int | TÜİK — kişi başı lig için |
| boundary | geometry(MultiPolygon,4326) | GIST index; import'ta ST_SimplifyPreserveTopology ile sadeleştirilmiş |

## reports
| Kolon | Tip | Not |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK→users | |
| location | geometry(Point,4326) | GIST index |
| province_id | smallint FK→provinces | Insert sırasında ST_Contains ile bulunur |
| severity | smallint 1–4 | 1 Tümsek sayılır 🟡 · 2 Jant sallanır 🟠 · 3 Lastik gider 🔴 · 4 Araç yutar ⚫ |
| category | enum | cukur, bozuk_asfalt, rogar, kasis, diger |
| description | varchar(280) NULL | |
| photo_path | text NULL | uploads/<uuid>.webp |
| status | enum | active, fixed, hidden, deleted |
| confirm_count / fixed_count / still_there_count / complaint_count | int default 0 | Denormalize; votes ile aynı transaction'da güncellenir |
| upvote_count / downvote_count | int default 0 | Feed sıralaması için (score = upvote_count - downvote_count); votes ile aynı transaction'da güncellenir |
| created_at / updated_at | timestamptz | |

## votes
| Kolon | Tip | Not |
|---|---|---|
| id | uuid PK | |
| report_id | uuid FK→reports | |
| user_id | uuid FK→users | |
| type | enum | confirm, fixed, still_there, complaint, upvote, downvote |
| created_at | timestamptz | |
| | | **UNIQUE(report_id, user_id, type)** → idempotent oy; oy değiştirme/geri alma yok (bilinen sınırlama, gelecekte ele alınacak) |

## Eşikler (env)
- `FIXED_THRESHOLD=5` → fixed_count eşiği aşınca status=fixed ("Belediye buraya el atmış 👏")
- `HIDE_THRESHOLD=3` → complaint_count eşiği aşınca status=hidden

Rozetler DB'de değil; kod içinde eşik tanımı (kullanıcı istatistiklerinden hesaplanır).
