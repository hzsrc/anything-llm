-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_temporary_auth_tokens" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "token" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_temporary_auth_tokens" ("createdAt", "expiresAt", "id", "token", "userId") SELECT "createdAt", "expiresAt", "id", "token", "userId" FROM "temporary_auth_tokens";
DROP TABLE "temporary_auth_tokens";
ALTER TABLE "new_temporary_auth_tokens" RENAME TO "temporary_auth_tokens";
CREATE UNIQUE INDEX "temporary_auth_tokens_token_key" ON "temporary_auth_tokens"("token");
CREATE INDEX "temporary_auth_tokens_token_idx" ON "temporary_auth_tokens"("token");
CREATE INDEX "temporary_auth_tokens_userId_idx" ON "temporary_auth_tokens"("userId");
CREATE TABLE "new_embed_chats" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "prompt" TEXT NOT NULL,
    "response" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,
    "include" BOOLEAN NOT NULL DEFAULT true,
    "connection_information" TEXT,
    "embed_id" INTEGER NOT NULL,
    "usersId" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "embed_chats_embed_id_fkey" FOREIGN KEY ("embed_id") REFERENCES "embed_configs" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_embed_chats" ("connection_information", "createdAt", "embed_id", "id", "include", "prompt", "response", "session_id", "usersId") SELECT "connection_information", "createdAt", "embed_id", "id", "include", "prompt", "response", "session_id", "usersId" FROM "embed_chats";
DROP TABLE "embed_chats";
ALTER TABLE "new_embed_chats" RENAME TO "embed_chats";
CREATE TABLE "new_workspace_threads" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "workspace_id" INTEGER NOT NULL,
    "user_id" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workspace_threads_workspace_id_fkey" FOREIGN KEY ("workspace_id") REFERENCES "workspaces" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_workspace_threads" ("createdAt", "id", "lastUpdatedAt", "name", "slug", "user_id", "workspace_id") SELECT "createdAt", "id", "lastUpdatedAt", "name", "slug", "user_id", "workspace_id" FROM "workspace_threads";
DROP TABLE "workspace_threads";
ALTER TABLE "new_workspace_threads" RENAME TO "workspace_threads";
CREATE UNIQUE INDEX "workspace_threads_slug_key" ON "workspace_threads"("slug");
CREATE INDEX "workspace_threads_workspace_id_idx" ON "workspace_threads"("workspace_id");
CREATE INDEX "workspace_threads_user_id_idx" ON "workspace_threads"("user_id");
CREATE TABLE "new_slash_command_presets" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "command" TEXT NOT NULL,
    "prompt" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "uid" INTEGER NOT NULL DEFAULT 0,
    "userId" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_slash_command_presets" ("command", "createdAt", "description", "id", "lastUpdatedAt", "prompt", "uid", "userId") SELECT "command", "createdAt", "description", "id", "lastUpdatedAt", "prompt", "uid", "userId" FROM "slash_command_presets";
DROP TABLE "slash_command_presets";
ALTER TABLE "new_slash_command_presets" RENAME TO "slash_command_presets";
CREATE UNIQUE INDEX "slash_command_presets_uid_command_key" ON "slash_command_presets"("uid", "command");
CREATE TABLE "new_recovery_codes" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "user_id" INTEGER NOT NULL,
    "code_hash" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_recovery_codes" ("code_hash", "createdAt", "id", "user_id") SELECT "code_hash", "createdAt", "id", "user_id" FROM "recovery_codes";
DROP TABLE "recovery_codes";
ALTER TABLE "new_recovery_codes" RENAME TO "recovery_codes";
CREATE INDEX "recovery_codes_user_id_idx" ON "recovery_codes"("user_id");
CREATE TABLE "new_workspace_users" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "user_id" INTEGER NOT NULL,
    "workspace_id" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workspace_users_workspace_id_fkey" FOREIGN KEY ("workspace_id") REFERENCES "workspaces" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_workspace_users" ("createdAt", "id", "lastUpdatedAt", "user_id", "workspace_id") SELECT "createdAt", "id", "lastUpdatedAt", "user_id", "workspace_id" FROM "workspace_users";
DROP TABLE "workspace_users";
ALTER TABLE "new_workspace_users" RENAME TO "workspace_users";
CREATE TABLE "new_workspace_chats" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "workspaceId" INTEGER NOT NULL,
    "prompt" TEXT NOT NULL,
    "response" TEXT NOT NULL,
    "include" BOOLEAN NOT NULL DEFAULT true,
    "user_id" INTEGER,
    "thread_id" INTEGER,
    "api_session_id" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "feedbackScore" BOOLEAN
);
INSERT INTO "new_workspace_chats" ("api_session_id", "createdAt", "feedbackScore", "id", "include", "lastUpdatedAt", "prompt", "response", "thread_id", "user_id", "workspaceId") SELECT "api_session_id", "createdAt", "feedbackScore", "id", "include", "lastUpdatedAt", "prompt", "response", "thread_id", "user_id", "workspaceId" FROM "workspace_chats";
DROP TABLE "workspace_chats";
ALTER TABLE "new_workspace_chats" RENAME TO "workspace_chats";
CREATE TABLE "new_embed_configs" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "uuid" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "chat_mode" TEXT NOT NULL DEFAULT 'query',
    "allowlist_domains" TEXT,
    "allow_model_override" BOOLEAN NOT NULL DEFAULT false,
    "allow_temperature_override" BOOLEAN NOT NULL DEFAULT false,
    "allow_prompt_override" BOOLEAN NOT NULL DEFAULT false,
    "max_chats_per_day" INTEGER,
    "max_chats_per_session" INTEGER,
    "workspace_id" INTEGER NOT NULL,
    "createdBy" INTEGER,
    "usersId" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "embed_configs_workspace_id_fkey" FOREIGN KEY ("workspace_id") REFERENCES "workspaces" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_embed_configs" ("allow_model_override", "allow_prompt_override", "allow_temperature_override", "allowlist_domains", "chat_mode", "createdAt", "createdBy", "enabled", "id", "max_chats_per_day", "max_chats_per_session", "usersId", "uuid", "workspace_id") SELECT "allow_model_override", "allow_prompt_override", "allow_temperature_override", "allowlist_domains", "chat_mode", "createdAt", "createdBy", "enabled", "id", "max_chats_per_day", "max_chats_per_session", "usersId", "uuid", "workspace_id" FROM "embed_configs";
DROP TABLE "embed_configs";
ALTER TABLE "new_embed_configs" RENAME TO "embed_configs";
CREATE UNIQUE INDEX "embed_configs_uuid_key" ON "embed_configs"("uuid");
CREATE TABLE "new_password_reset_tokens" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "user_id" INTEGER NOT NULL,
    "token" TEXT NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "new_password_reset_tokens" ("createdAt", "expiresAt", "id", "token", "user_id") SELECT "createdAt", "expiresAt", "id", "token", "user_id" FROM "password_reset_tokens";
DROP TABLE "password_reset_tokens";
ALTER TABLE "new_password_reset_tokens" RENAME TO "password_reset_tokens";
CREATE UNIQUE INDEX "password_reset_tokens_token_key" ON "password_reset_tokens"("token");
CREATE INDEX "password_reset_tokens_user_id_idx" ON "password_reset_tokens"("user_id");
CREATE TABLE "new_browser_extension_api_keys" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "key" TEXT NOT NULL,
    "user_id" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" DATETIME NOT NULL
);
INSERT INTO "new_browser_extension_api_keys" ("createdAt", "id", "key", "lastUpdatedAt", "user_id") SELECT "createdAt", "id", "key", "lastUpdatedAt", "user_id" FROM "browser_extension_api_keys";
DROP TABLE "browser_extension_api_keys";
ALTER TABLE "new_browser_extension_api_keys" RENAME TO "browser_extension_api_keys";
CREATE UNIQUE INDEX "browser_extension_api_keys_key_key" ON "browser_extension_api_keys"("key");
CREATE INDEX "browser_extension_api_keys_user_id_idx" ON "browser_extension_api_keys"("user_id");
CREATE TABLE "new_workspace_agent_invocations" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "uuid" TEXT NOT NULL,
    "prompt" TEXT NOT NULL,
    "closed" BOOLEAN NOT NULL DEFAULT false,
    "user_id" INTEGER,
    "thread_id" INTEGER,
    "workspace_id" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUpdatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "workspace_agent_invocations_workspace_id_fkey" FOREIGN KEY ("workspace_id") REFERENCES "workspaces" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_workspace_agent_invocations" ("closed", "createdAt", "id", "lastUpdatedAt", "prompt", "thread_id", "user_id", "uuid", "workspace_id") SELECT "closed", "createdAt", "id", "lastUpdatedAt", "prompt", "thread_id", "user_id", "uuid", "workspace_id" FROM "workspace_agent_invocations";
DROP TABLE "workspace_agent_invocations";
ALTER TABLE "new_workspace_agent_invocations" RENAME TO "workspace_agent_invocations";
CREATE UNIQUE INDEX "workspace_agent_invocations_uuid_key" ON "workspace_agent_invocations"("uuid");
CREATE INDEX "workspace_agent_invocations_uuid_idx" ON "workspace_agent_invocations"("uuid");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
