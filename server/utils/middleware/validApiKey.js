const { ApiKey } = require("../../models/apiKeys");
const { SystemSettings } = require("../../models/systemSettings");
const { validatedRequest } = require("./validatedRequest");

async function validApiKey(request, response, next) {
  const multiUserMode = await SystemSettings.isMultiUserMode();
  response.locals.multiUserMode = multiUserMode;

  const auth = request.header("Authorization");
  const bearerKey = auth ? auth.split(" ")[1] : null;
  if (!bearerKey) {
    response.status(403).json({
      error: "No valid api key found.",
    });
    return;
  }

  if (!(await ApiKey.get({ secret: bearerKey }))) {
    var ok = false
    await validatedRequest(request, response, () => ok= true)
    if (!ok) {
      response.status(403).json({
        error: "No valid api key found.",
      });
      return;
    }
  }

  next();
}

module.exports = {
  validApiKey,
};
