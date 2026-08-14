-- CreateTable
CREATE TABLE "Repository" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "description" TEXT,
    "isPrivate" INTEGER NOT NULL DEFAULT 0,
    "starCount" INTEGER NOT NULL DEFAULT 0,
    "forkCount" INTEGER NOT NULL DEFAULT 0,
    "openIssues" INTEGER NOT NULL DEFAULT 0,
    "openPRs" INTEGER NOT NULL DEFAULT 0,
    "lastActivity" DATETIME,
    "healthScore" INTEGER NOT NULL DEFAULT 0,
    "healthStatus" TEXT NOT NULL DEFAULT 'UNKNOWN',
    "hasProtection" INTEGER NOT NULL DEFAULT 0,
    "requiredChecks" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "WorkItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "areaPath" TEXT,
    "iterationPath" TEXT,
    "assignedTo" TEXT,
    "organization" TEXT NOT NULL,
    "project" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "WorkItemLink" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "repositoryId" TEXT NOT NULL,
    "workItemId" TEXT NOT NULL,
    "pullRequestId" TEXT,
    "commitSha" TEXT,
    "linkType" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "WorkItemLink_repositoryId_fkey" FOREIGN KEY ("repositoryId") REFERENCES "Repository" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "WorkItemLink_workItemId_fkey" FOREIGN KEY ("workItemId") REFERENCES "WorkItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "HealthCheck" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "repositoryId" TEXT NOT NULL,
    "checkType" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "message" TEXT,
    "details" TEXT,
    "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "HealthCheck_repositoryId_fkey" FOREIGN KEY ("repositoryId") REFERENCES "Repository" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Report" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "type" TEXT NOT NULL,
    "week" INTEGER NOT NULL,
    "year" INTEGER NOT NULL,
    "content" TEXT NOT NULL,
    "htmlContent" TEXT,
    "summary" TEXT,
    "repositoryId" TEXT,
    "generatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Report_repositoryId_fkey" FOREIGN KEY ("repositoryId") REFERENCES "Repository" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SyncLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "repositoryId" TEXT,
    "syncType" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "itemsProcessed" INTEGER NOT NULL DEFAULT 0,
    "itemsFailed" INTEGER NOT NULL DEFAULT 0,
    "errorMessage" TEXT,
    "details" TEXT,
    "startedAt" DATETIME NOT NULL,
    "completedAt" DATETIME,
    "duration" INTEGER,
    CONSTRAINT "SyncLog_repositoryId_fkey" FOREIGN KEY ("repositoryId") REFERENCES "Repository" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "githubUsername" TEXT,
    "azureId" TEXT,
    "role" TEXT NOT NULL DEFAULT 'VIEWER',
    "lastLogin" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "Repository_name_key" ON "Repository"("name");

-- CreateIndex
CREATE INDEX "WorkItemLink_workItemId_idx" ON "WorkItemLink"("workItemId");

-- CreateIndex
CREATE INDEX "WorkItemLink_repositoryId_idx" ON "WorkItemLink"("repositoryId");

-- CreateIndex
CREATE UNIQUE INDEX "WorkItemLink_repositoryId_workItemId_pullRequestId_key" ON "WorkItemLink"("repositoryId", "workItemId", "pullRequestId");

-- CreateIndex
CREATE INDEX "HealthCheck_repositoryId_timestamp_idx" ON "HealthCheck"("repositoryId", "timestamp");

-- CreateIndex
CREATE INDEX "Report_type_year_week_idx" ON "Report"("type", "year", "week");

-- CreateIndex
CREATE UNIQUE INDEX "Report_type_week_year_key" ON "Report"("type", "week", "year");

-- CreateIndex
CREATE INDEX "SyncLog_syncType_status_idx" ON "SyncLog"("syncType", "status");

-- CreateIndex
CREATE INDEX "SyncLog_startedAt_idx" ON "SyncLog"("startedAt");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_githubUsername_key" ON "User"("githubUsername");

-- CreateIndex
CREATE UNIQUE INDEX "User_azureId_key" ON "User"("azureId");
