const { v4: uuidv4 } = require("uuid");
const { reqBody, userFromSession, multiUserMode } = require("../utils/http");
const { validatedRequest } = require("../utils/middleware/validatedRequest");
const { Telemetry } = require("../models/telemetry");
const { streamChatWithWorkspace } = require("../utils/chats/stream");
const {
  ROLES,
  flexUserRoleValid,
} = require("../utils/middleware/multiUserProtected");
const { EventLogs } = require("../models/eventLogs");
const {
  validWorkspaceAndThreadSlug,
  validWorkspaceSlug,
} = require("../utils/middleware/validWorkspace");
const { writeResponseChunk } = require("../utils/helpers/chat/responses");
const { WorkspaceThread } = require("../models/workspaceThread");
const { User } = require("../models/user");
const truncate = require("truncate");
const { WorkspaceChats } = require("../models/workspaceChats");
const { getLLMProvider } = require("../utils/helpers");

function chatEndpoints(app) {
  if (!app) return;

  app.post(
    "/workspace/:slug/stream-chat",
    [validatedRequest, flexUserRoleValid([ROLES.all]), validWorkspaceSlug],
    async (request, response) => {
      try {
        const user = await userFromSession(request, response);
        const { message, attachments = [] } = reqBody(request);
        const workspace = response.locals.workspace;

        if (!message?.length) {
          response.status(400).json({
            id: uuidv4(),
            type: "abort",
            textResponse: null,
            sources: [],
            close: true,
            error: !message?.length ? "Message is empty." : null,
          });
          return;
        }

        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Content-Type", "text/event-stream");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Connection", "keep-alive");
        response.flushHeaders();

        if (multiUserMode(response) && !(await User.canSendChat(user))) {
          writeResponseChunk(response, {
            id: uuidv4(),
            type: "abort",
            textResponse: null,
            sources: [],
            close: true,
            error: `You have met your maximum 24 hour chat quota of ${user.dailyMessageLimit} chats. Try again later.`,
          });
          return;
        }

        await streamChatWithWorkspace(
          response,
          workspace,
          message,
          workspace?.chatMode,
          user,
          null,
          attachments
        );
        await Telemetry.sendTelemetry("sent_chat", {
          multiUserMode: multiUserMode(response),
          LLMSelection: process.env.LLM_PROVIDER || "openai",
          Embedder: process.env.EMBEDDING_ENGINE || "inherit",
          VectorDbSelection: process.env.VECTOR_DB || "lancedb",
          multiModal: Array.isArray(attachments) && attachments?.length !== 0,
          TTSSelection: process.env.TTS_PROVIDER || "native",
        });

        await EventLogs.logEvent(
          "sent_chat",
          {
            workspaceName: workspace?.name,
            chatModel: workspace?.chatModel || "System Default",
          },
          user?.id
        );
        response.end();
      } catch (e) {
        console.error(e);
        writeResponseChunk(response, {
          id: uuidv4(),
          type: "abort",
          textResponse: null,
          sources: [],
          close: true,
          error: e.message,
        });
        response.end();
      }
    }
  );

  app.post(
    "/workspace/:slug/thread/:threadSlug/stream-chat",
    [
      validatedRequest,
      flexUserRoleValid([ROLES.all]),
      validWorkspaceAndThreadSlug,
    ],
    async (request, response) => {
      try {
        const user = await userFromSession(request, response);
        const { message, attachments = [] } = reqBody(request);
        const workspace = response.locals.workspace;
        const thread = response.locals.thread;

        if (!message?.length) {
          response.status(400).json({
            id: uuidv4(),
            type: "abort",
            textResponse: null,
            sources: [],
            close: true,
            error: !message?.length ? "Message is empty." : null,
          });
          return;
        }

        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Content-Type", "text/event-stream");
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Connection", "keep-alive");
        response.flushHeaders();

        if (multiUserMode(response) && !(await User.canSendChat(user))) {
          writeResponseChunk(response, {
            id: uuidv4(),
            type: "abort",
            textResponse: null,
            sources: [],
            close: true,
            error: `You have met your maximum 24 hour chat quota of ${user.dailyMessageLimit} chats. Try again later.`,
          });
          return;
        }

        await streamChatWithWorkspace(
          response,
          workspace,
          message,
          workspace?.chatMode,
          user,
          thread,
          attachments
        );

        // If thread was renamed emit event to frontend via special `action` response.
        await WorkspaceThread.autoRenameThread({
          thread,
          workspace,
          user,
          newName: truncate(message, 22),
          onRename: (thread) => {
            writeResponseChunk(response, {
              action: "rename_thread",
              thread: {
                slug: thread.slug,
                name: thread.name,
              },
            });
          },
        });

        await Telemetry.sendTelemetry("sent_chat", {
          multiUserMode: multiUserMode(response),
          LLMSelection: process.env.LLM_PROVIDER || "openai",
          Embedder: process.env.EMBEDDING_ENGINE || "inherit",
          VectorDbSelection: process.env.VECTOR_DB || "lancedb",
          multiModal: Array.isArray(attachments) && attachments?.length !== 0,
          TTSSelection: process.env.TTS_PROVIDER || "native",
        });

        await EventLogs.logEvent(
          "sent_chat",
          {
            workspaceName: workspace.name,
            thread: thread.name,
            chatModel: workspace?.chatModel || "System Default",
          },
          user?.id
        );
        response.end();
      } catch (e) {
        console.error(e);
        writeResponseChunk(response, {
          id: uuidv4(),
          type: "abort",
          textResponse: null,
          sources: [],
          close: true,
          error: e.message,
        });
        response.end();
      }
    }
  );

  app.post(
    "/workspace/:slug/thread/:threadSlug/generate",
    [
      validatedRequest,
      flexUserRoleValid([ROLES.all]),
      validWorkspaceAndThreadSlug,
    ],
    async (request, response) => {
      try {
        const user = await userFromSession(request, response);
        const { message, attachments = [], model, context, temperature } = reqBody(request);
        const workspace = response.locals.workspace;
        const thread = response.locals.thread;

        if (!message?.length) {
          response.status(400).json({
            id: uuidv4(),
            type: "abort",
            textResponse: null,
            sources: [],
            close: true,
            error: !message?.length ? "Message is empty." : null,
          });
          return;
        }

        if (multiUserMode(response) && !(await User.canSendChat(user))) {
          response.status(500).json(`You have met your maximum 24 hour chat quota of ${user.dailyMessageLimit} chats. Try again later.`);
          return;
        }

        const LLMConnector = getLLMProvider({
          provider: workspace?.chatProvider,
          model: workspace?.chatModel,
        });
        const system = workspace.openAiPrompt + '\n' + (context || '')
        const pars = { prompt: message, model, system, images: attachments || [] }
        console.log('api', model, system, prompt, context)
        const ret = await LLMConnector.generate(pars, {
          temperature: temperature || workspace?.openAiTemp || LLMConnector.defaultTemp,
        });

        let newName = truncate(message, 22)
        // If thread was renamed emit event to frontend via special `action` response.
        await WorkspaceThread.autoRenameThread({
          thread,
          workspace,
          user,
          newName,
          onRename: (thread) => {
            newName = thread.name
          },
        });

        // await Telemetry.sendTelemetry("sent_chat", {
        //   multiUserMode: multiUserMode(response),
        //   LLMSelection: process.env.LLM_PROVIDER || "openai",
        //   Embedder: process.env.EMBEDDING_ENGINE || "inherit",
        //   VectorDbSelection: process.env.VECTOR_DB || "lancedb",
        //   multiModal: Array.isArray(attachments) && attachments?.length !== 0,
        //   TTSSelection: process.env.TTS_PROVIDER || "native",
        // });
        //
        // await EventLogs.logEvent(
        //   "sent_chat",
        //   {
        //     workspaceName: workspace.name,
        //     thread: thread.name,
        //     chatModel: workspace?.chatModel || "System Default",
        //   },
        //   user?.id
        // );

        const { chat } = await WorkspaceChats.new({
          workspaceId: workspace.id,
          prompt: message,
          response: {
            text: ret.textResponse,
            sources: [],
            type: 'chat',
            attachments,
          },
          threadId: thread?.id || null,
          include: true,
          user,
        });

        if(chat) ret.chatId = chat.id;
        response.status(200).json(ret);
        response.end();
      } catch (e) {
        console.error(e);
        response.status(500).json({
          id: uuidv4(),
          type: "abort",
          textResponse: null,
          sources: [],
          close: true,
          error: e.message,
        });
        response.end();
      }
    }
  );
}

module.exports = { chatEndpoints };
