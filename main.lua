local Discordia = require('discordia')
require("discordia-interactions")
require("discordia-components")

local DiscordiaSlash = require('discordia-slash')
local Token = require('./secret')
local Commands = require('./commands')

local client = Discordia.Client():useApplicationCommands()
local interactionType = Discordia.enums.interactionType

local timer = require('timer')

local PendingSubmissions = {}
_G.PendingSubmissions = PendingSubmissions

local ActiveGiveaways = {}
_G.ActiveGiveaways = ActiveGiveaways

local WelcomeChannelID = "1479809457415520378"
local RatingsChannelID = "1513466061855522816"

local GuildID = "1476539200026316993"

client:on('ready', function()
    local ExistingCommands = client:getGuildApplicationCommands(GuildID)

    if ExistingCommands then
        for CommandID in pairs(ExistingCommands) do
            client:deleteGuildApplicationCommand(GuildID, CommandID)
        end
    end

	for _, CommandData in pairs(Commands) do
        if CommandData.Data then
            client:createGuildApplicationCommand(GuildID, CommandData.Data)
        end
    end
    print("G1cF-vN-Sl sV:Lx:Gz | [INFO]    | 🐸 Frog Servant : Sire, I have initialized, you may continue with using your Application Commands now, your majesty.")
end)

client:on('slashCommand', function(Interaction, cmd, Arguments)
	Interaction:replyDeferred(false)

	for _, CommandData in pairs(Commands) do
  		if CommandData.Data.name == cmd.name then
			CommandData.OnRan(Interaction, cmd, Arguments, Discordia.Color, Discordia.Date)
  		end
	end
end)

client:on('messageCreate', function(message)
    if message.author.bot then return end

    if message.content == '!ping' then
        message.channel:send('Pong!')
    elseif message.channel.id == RatingsChannelID then
        message:addReaction('🔥')
    end
end)

---@param interaction Interaction
client:on('interactionCreate', function(interaction)
    if interaction.type == interactionType.applicationCommand then
        return
    end

    local InteractionID = interaction.data.custom_id
    local Guild = interaction.guild
    local I = Guild.me
    local Executor = interaction.member

    local Data = _G.PendingSubmissions[Executor.id]

    if Data then 
        if InteractionID == "submit_confirm_" .. Executor.id then
            -- interaction:update({content = "⏳ **Processing...**", components = {}, embed = {}})

            local channel = Guild:getChannel(Data.channelId)

            channel:send({
                embed = {
                    description = Data.description,
                    fields = {}
                };
            })
        
            interaction:update({content = "✅ **Successfully submitted!**", components = {}})
            
            local Reply = interaction:getReply()

            if Reply then
                Reply:hideEmbeds()
            end
        elseif InteractionID == "submit_cancel_" .. Executor.id then
            interaction:update({content = "❌ **Submission cancelled.**", components = {}})

            local Reply = interaction:getReply()
            
            if Reply then
                Reply:hideEmbeds()
            end
        end

        _G.PendingSubmissions[Executor.id] = nil
        return
    end

    if InteractionID == "giveaway_enter" then
        local messageId = interaction.message.id
        local giveaway = _G.ActiveGiveaways[messageId]

        if not giveaway then
            interaction:reply({content = "❌ **This giveaway has ended!**", ephemeral = true})
            return
        end

        -- check if already entered
        for _, id in ipairs(giveaway.entrants) do
            if id == Executor.id then
                interaction:reply({content = "❌ **You already entered this giveaway!**", ephemeral = true})
                return
            end
        end

        table.insert(giveaway.entrants, Executor.id)

        interaction:update({
            embed = {
                title = "🎉 Giveaway!",
                description = "**Prize:** " .. giveaway.prize .. "\n\n**Ends:** <t:" .. giveaway.EndTime .. ":R>\n\n**Hosted by:** <@" .. giveaway.hostId .. ">",
                color = 0xFF69B4,
                fields = {
                    { name = "Participants", value = tostring(#giveaway.entrants), inline = true }
                }
            },
            components = {
                {
                    type = 1,
                    components = {
                        { type = 2, style = 1, label = "🎉 Enter (" .. #giveaway.entrants .. ")", custom_id = "giveaway_enter" }
                    }
                }
            }
        })

        return 
    elseif InteractionID == "verify" then
        local HasSucceeded = Executor:addRole("1483578478657011712")
        if not HasSucceeded then
            interaction:reply("❌ **Failed!**", true)
        else
            interaction:reply("✅ **Succeeded**!", true)
        end
    end
end)

client:on('memberJoin', function(member)
    print("member joined!!")
    coroutine.wrap(function()
        local Guild = member.guild
        
        local Channel = Guild:getChannel(WelcomeChannelID)
        if not Channel then return end

        Channel:send({
            content = "<@" .. member.id .. ">",
            embed = {
                title = "Welcome to " .. Guild.name .. "!",
                description = "Hey <@" .. member.id .. ">, welcome to **Green's Portfolio**! You are member #" .. Guild.memberCount .. ".",
                color = 0x00FF00,
                thumbnail = { url = member.user:getAvatarURL() },
                footer = { text = "Joined " .. Guild.name }
            }
        })
    end)()
end)

timer.setInterval(10000, function()
    coroutine.wrap(function()
    
    local TimeNow = os.time()

    for MessageID, Data in pairs(_G.ActiveGiveaways) do
        if TimeNow >= Data.EndTime then
            local Guild = client:getGuild(Data.guildId)
            if not Guild then return end

            local Channel = Guild:getChannel(Data.channelId)
            if not Channel then return end

            local Message = Channel:getMessage(Data.messageId)
            if not Message then return end

            local Entrants = Data.entrants

            if #Entrants <= 0 then
                Channel:send("🎉 The giveaway for **" .. Data.prize .. "** ended but nobody entered!")
            else
                local winnerMentions = {}
                local numWinners = math.min(Data.winners, #Entrants)

                for i = 1, numWinners do
                    local index = math.random(1, #Entrants)
                    table.insert(winnerMentions, "<@" .. Entrants[index] .. ">")
                    table.remove(Entrants, index)
                end

                print("ended!")

                Channel:send("**Prize:** " .. Data.prize .. "\n\n**Winner(s):** " .. table.concat(winnerMentions, ", "))

                _G.ActiveGiveaways[Data.messageId] = nil
            end
        end
    end


    end)()
end)

client:run("Bot "..Token.BotToken)