-- AlterEnum
ALTER TYPE "vote_type" ADD VALUE 'upvote';
ALTER TYPE "vote_type" ADD VALUE 'downvote';

-- AlterTable
ALTER TABLE "reports" ADD COLUMN     "downvote_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "upvote_count" INTEGER NOT NULL DEFAULT 0;
