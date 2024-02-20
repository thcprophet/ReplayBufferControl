function script_description()
    return "Replay Buffer Control (RBC) tries to achieve what NVIDIA's Shadowplay does, it eliminates the previous buffer in a near seamless way garanting a better clipping experience."
end

refreshRate = 10

-- Called to set default values of data settings
function script_defaults(settings)
  obs.obs_data_set_default_double(settings, "refreshRate", 100)
end

-- Called to display the properties GUI
function script_properties()
  props = obs.obs_properties_create()
  obs.obs_properties_add_float_slider(props, "refreshRate", "Refresh Rate", 10, 1000, 5)
  return props
end

-- Called after change of settings including once after script load
function script_update(settings)
  refreshRate = obs.obs_data_get_double(settings, "refreshRate")
end

obs = obslua

-- Define replay buffer status constants
local REPLAY_BUFFER_STATUS = {
    STARTING = 1,
    STARTED = 2,
    STOPPING = 3,
    STOPPED = 4,
    SAVED = 5
}

-- Variable to store the current status of the replay buffer
local replayBufferStatus = REPLAY_BUFFER_STATUS.STOPPED

-- Function to start the replay buffer
local function startReplayBuffer()
    obs.obs_frontend_replay_buffer_start()
end

-- Function to stop and then start the replay buffer
local function restartReplayBuffer()
    obs.obs_frontend_replay_buffer_stop()
    startReplayBuffer()  -- Start the replay buffer after stopping
end

-- Function to check and restart the replay buffer if it's stopped
local function checkAndRestartReplayBuffer()
    if replayBufferStatus == REPLAY_BUFFER_STATUS.STOPPED then
        startReplayBuffer()  -- Restart the replay buffer if it's stopped
    end
end

-- Register a timer to periodically check and restart the replay buffer
obs.timer_add(checkAndRestartReplayBuffer, refreshRate)  -- Controls how often the status of the replay buffer is checked

-- Hook function for saving the replay buffer
local function onReplayBufferSave(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        restartReplayBuffer()  -- Stop the replay buffer
    end
end

-- Hook function for updating the replay buffer status
local function updateReplayBufferStatus(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTING then
        replayBufferStatus = REPLAY_BUFFER_STATUS.STARTING
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED then
        replayBufferStatus = REPLAY_BUFFER_STATUS.STARTED
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPING then
        replayBufferStatus = REPLAY_BUFFER_STATUS.STOPPING
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED then
        replayBufferStatus = REPLAY_BUFFER_STATUS.STOPPED
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        replayBufferStatus = REPLAY_BUFFER_STATUS.SAVED
    end
end

-- Register the hook for saving the replay buffer
obs.obs_frontend_add_event_callback(onReplayBufferSave)

-- Register the hook for updating the replay buffer status
obs.obs_frontend_add_event_callback(updateReplayBufferStatus)

-- Define a function to get the current status of the replay buffer
local function getReplayBufferStatus()
    return replayBufferStatus
end

-- Define a function to be called when the script is unloaded
function script_unload()
    obs.obs_frontend_remove_event_callback(onReplayBufferSave)
    obs.obs_frontend_remove_event_callback(updateReplayBufferStatus)
end
