local Lines = {
    ["BanExecutorNoHavePerm"] = "You do not have permission, little one.";
    ["BanBotNoHavePerm"] = "Hey sire, I do not have permission, could you fix that, great master?";
    ["BanExecutorRoleLessOrEqualTargetRole"] = "Hey sire, Your role is less than or equal to the victim's role, you cannot ban him, great master.";
    ["BanBotRoleLowerThanTargetRole"] = "Hey sire, My role is less than or equal to the victim's role, could you fix that, great master?";
    ["BanNoTargetFound"] = "Hey sire, I could not find that victim of yours, can you retry, great master?";
    ["BanMessage"] = '## 🔨 **%s** has been banned.\n> **Reason:** %s';
}

local PastWorkChannelID = "1476847196501442582"
local GamesChannelID = "1476539592395198598"
local ManagementGamesChannelID = "1476617297606086871"
local StudiosChannelID = "1516855864714330203"
local ClientRatingChannelID = "1513466061855522816"
local VerifyChannelID = "1517153136597532792"

local ClientRoleID = "1476540092452442223"

local discordia = require('discordia')

return {
    {
        Data = {
            name = "ban",
            description = "Bans a user from the server.",
            options = {
                {
                    name = "user",
                    description = "The user you want to ban (type their name or mention them)",
                    type = 6, -- Type 6 is 'USER' from the enums documentation
                    required = true
                },
                {
                    name = "reason",
                    description = "Why are you banning this user?",
                    type = 3, -- Type 3 is 'STRING' from the enums documentation
                    required = false
                }
            }
        };

        ---@param interaction Interaction
        OnRan = function(interaction, cmd, args)
            local Guild = interaction.guild
            local I = Guild.me
            local Executor = interaction.member
            local Target = Guild:getMember(args.user) -- args.user is the user ID
            local BanReason = args.reason or "No reason specified."

            if not Executor:hasPermission("banMembers") then
                interaction:editReply({content = Lines["BanExecutorNoHavePerm"], ephemeral = false})
            return end

            if not I:hasPermission("banMembers") then
                interaction:editReply({content = Lines["BanBotNoHavePerm"], ephemeral = false})
            return end

            if not Target then
                interaction:editReply({content = Lines["BanNoTargetFound"], ephemeral = false})
            return end

            if Executor.highestRole.position <= Target.highestRole.position then
                interaction:editReply({content = Lines["BanExecutorRoleLessOrEqualTargetRole"], ephemeral = false})
            return end

            if I.highestRole.position <= Target.highestRole.position then
                interaction:editReply({content = Lines["BanBotRoleLowerThanTargetRole"], ephemeral = false})
            return end

            local banSuccess = Guild:banUser(Target.id, BanReason, 0)

            if banSuccess then
                interaction:editReply(string.format(Lines["BanMessage"], Target.user.username, BanReason))
            else
                interaction:editReply({content = "Something went wrong. Please report this to green.", ephemeral = false})
            end
        end;
    };

    {
        Data = {
            name = "submit",
            description = "Submits past work into the past work channel / submits games in the games channel.",
            default_member_permissions = "0",
            options = {
                {
                    name = "type",
                    description = "channel type",
                    type = 3,
                    required = true,
                },
                {
                    name = "typename",
                    description = "game name/ past work name",
                    type = 3,
                    required = false,
                },
                {
                    name = "typedescription",
                    description = "description of the thing",
                    type = 3,
                    required = false,
                },
                {
                    name = "typelink",
                    description = "link for the type (game/past work)",
                    type = 3,
                    required = false,
                },
                {
                    name = "typegenre",
                    description = "genre of the game (for games)",
                    type = 3,
                    required = false,
                },
                {
                    name = "typestatus",
                    description = "game status (for games)",
                    type = 3,
                    required = false,
                },
                {
                    name = "extralink",
                    description = "extra link to add (for past work)",
                    type = 3,
                    required = false,
                },
                {
                    name = "role",
                    description = "your role (for management contributed games)",
                    type = 3,
                    required = false,
                },
            }
        };

        ---@param interaction Interaction
        OnRan = function(interaction, cmd, args, color, date)
            local Guild = interaction.guild
            local I = Guild.me
            local Executor = interaction.member

            if Executor.highestRole.position <= I.highestRole.position then
                interaction:editReply({
                    content = "❌ **You do not have permission to submit!**"
            }) return end

            local Name = args.typename
            if not Name then
                interaction:editReply({content = "❌ **Please specify the name!**"})
            return end

            local Link = args.typelink
            if not Link then
                interaction:editReply({content = "❌ **Please specify the link of the discord server!**"})
            return end

            local Description = args.typedescription
            if not Description then
                interaction:editReply({content = "❌ **Please specify the description!**"})
            return end

            local ChannelType = string.lower(args.type)

            if ChannelType == "past work" then
                local channel = Guild:getChannel(PastWorkChannelID)

                if not channel then
                    interaction:editReply({content = "❌ **Sire, I was not able to find the past work channel!**"})
                return end

                local ExtraLink = args.extralink
                if not ExtraLink then
                    interaction:editReply({content = "❌ **Please add a video showcasing the system, don't be lazy sire <@1210538079648219149>**"})
                return end

                local NewDescription = "# ["..Name.."]("..Link..")".. "\n\n"..Description

                _G.PendingSubmissions[Executor.id] = {
                    description = NewDescription,
                    channelId = PastWorkChannelID,
                    link = ExtraLink;
                    linkName = (string.find(ExtraLink, "discord") and "Discord" or string.find(ExtraLink, "youtube") and "YouTube" or "Web")
                }

                interaction:editReply({
                    embed = {
                        title = "📋 **Preview your past work submission: **\n",
                        description = NewDescription,
                        fields = {};
                    };
                    components = {
                        {
                            type = 1,
                            components = {
                                { type = 2, style = 3, label = "✅ Confirm", custom_id = "submit_confirm_" .. Executor.id },
                                { type = 2, style = 4, label = "❌ Cancel", custom_id = "submit_cancel_" .. Executor.id }
                            }
                        }
                    }
                })

            elseif ChannelType == "contributed games" then
                local channel = Guild:getChannel(GamesChannelID)
                if not channel then
                    interaction:editReply({content = "❌ **Couldn't find the contributed games channel! Sire help me!**"})
                return end

                local Genre = args.typegenre
                if not Genre then
                    interaction:editReply({content = "❌ **Sire, Please specify the genre!**"})
                return end

                local Status = args.typestatus or "In-Dev"

                local NewDescription = "# " .. Name .. "\n\n### Genre: " .. Genre .. "\n\n" .. Description .. "\n\n# Status: ".. args.typestatus.."\n"..args.typelink

                _G.PendingSubmissions[Executor.id] = {
                    description = NewDescription,
                    channelId = GamesChannelID,
                }
                
                interaction:editReply({
                    embed = {
                        title = "📋 **Preview your submission: **\n",
                        description = NewDescription,
                        fields = {};
                    };
                    components = {
                        {
                            type = 1,
                            components = {
                                { type = 2, style = 3, label = "✅ Confirm", custom_id = "submit_confirm_" .. Executor.id },
                                { type = 2, style = 4, label = "❌ Cancel", custom_id = "submit_cancel_" .. Executor.id }
                            }
                        }
                    }
                })
            elseif ChannelType == "management contributed games" then
                local channel = Guild:getChannel(ManagementGamesChannelID)
                if not channel then
                    interaction:editReply({content = "❌ **Couldn't find the management contributed games channel! Sire help me!**"})
                return end

                local Genre = args.typegenre
                if not Genre then
                    interaction:editReply({content = "❌ **Sire, Please specify the genre!**"})
                return end

                local Role = args.role or "Server Manager"
                if not Genre then
                    interaction:editReply({content = "❌ **Sire, Please specify the role!**"})
                return end

                local Status = args.typestatus or "In-Dev"

                local NewDescription = "# " .. Name .. "\n\n### Genre: " .. Genre .. "\n\n" .. Description .. "\n\n## Status: ".. args.typestatus.."\n## Role: "..Role.."\n"..args.typelink

                _G.PendingSubmissions[Executor.id] = {
                    description = NewDescription,
                    channelId = ManagementGamesChannelID,
                }
                
                interaction:editReply({
                    embed = {
                        title = "📋 **Preview your submission: **\n",
                        description = NewDescription,
                        fields = {};
                    };
                    components = {
                        {
                            type = 1,
                            components = {
                                { type = 2, style = 3, label = "✅ Confirm", custom_id = "submit_confirm_" .. Executor.id },
                                { type = 2, style = 4, label = "❌ Cancel", custom_id = "submit_cancel_" .. Executor.id }
                            }
                        }
                    }
                })
            elseif ChannelType == "studios" then
                local Status = args.typestatus or "In-Dev"

                local NewDescription = "# "..Name.."\n## Link: "..Link.."\n## Status: "..Status.."\n" .. Description .."\n\n-# Note: I will not regularly update this message, if you want the latest info you can join the server mentioned above for the latest info (if mentioned.)"

                _G.PendingSubmissions[Executor.id] = {
                    description = NewDescription,
                    channelId = StudiosChannelID,
                }
                
                interaction:editReply({
                    embed = {
                        title = "📋 **Preview your submission: **\n",
                        description = NewDescription,
                        fields = {};
                    };
                    components = {
                        {
                            type = 1,
                            components = {
                                { type = 2, style = 3, label = "✅ Confirm", custom_id = "submit_confirm_" .. Executor.id },
                                { type = 2, style = 4, label = "❌ Cancel", custom_id = "submit_cancel_" .. Executor.id }
                            }
                        }
                    }
                })
            else
                interaction:editReply("❌ Please choose one of the following types to post. \n- past work \n- contributed games \n- studios \n- management contributed games")
            end
        end;
    };

    {
        Data = {
            name = "submitrating",
            description = "Submits a rating, only available to Clients/Customers",
            options = {
                {
                    name = "speed",
                    description = "Rate how I handled the speed of your system out of 5",
                    type = 3,
                    required = true
                },
                {
                    name = "quality",
                    description = "Rate how I handled the quality of your system out of 5",
                    type = 3, -- Type 3 is 'STRING' from the enums documentation
                    required = true
                },
                {
                    name = "extradescription",
                    description = "Here you can describe more info",
                    type = 3, -- Type 3 is 'STRING' from the enums documentation
                    required = false
                },
            }
        };

        ---@param interaction Interaction
        OnRan = function(interaction, cmd, args)
            local Guild = interaction.guild
            local I = Guild.me
            local Executor = interaction.member

            local ClientRole = Guild:getRole(ClientRoleID)

            if Executor.highestRole.position <= ClientRole.position then
                interaction:editReply("❌ **You do not have the permissions to use this command!**")
            return end

            local Speed = args.speed:gsub("/%d+$", "")
            local Quality = args.quality:gsub("/%d+$", "")

            local SpeedNumber = tonumber(Speed)
            local QualityNumber = tonumber(Quality)

            local SpeedStars = ""
            local QualityStars = ""

            if type(SpeedNumber) == "number" then
                if SpeedNumber >= 5 then
                    SpeedNumber = 5
                    Speed = "5"
                end

                for i = 1, SpeedNumber do
                    SpeedStars = SpeedStars .. "⭐"
                end

                local Decimals = math.abs(SpeedNumber - math.floor(SpeedNumber))

                if Decimals >= 0.5 then
                    repeat
                        Decimals = Decimals - 0.5
                        SpeedStars = SpeedStars .. "<:half_star:1515623729072181288>"
                    until Decimals < 0.5
                end
            else
                interaction:editReply("❌ **Please specify a valid Speed Rating number!**")
            return end

            if type(QualityNumber) == "number" then
                if QualityNumber >= 5 then
                    QualityNumber = 5
                    Quality = "5"
                end

                for i = 1, QualityNumber do
                    QualityStars = QualityStars .. "⭐"
                end

                local Decimals = math.abs(QualityNumber - math.floor(QualityNumber))

                if Decimals >= 0.5 then
                    repeat
                        Decimals = Decimals - 0.5
                        QualityStars = QualityStars .. "<:half_star:1515623729072181288>"
                    until Decimals < 0.5
                end
            else
                interaction:editReply("❌ **Please specify a valid Quality Rating number!**")
            return end

            local ExtraDescription = args.extradescription

            if not ExtraDescription then
                ExtraDescription = "No extra information."
            elseif ExtraDescription then
                ExtraDescription = "### Extra Information:\n" .. ExtraDescription
            end

            local NewDescription = 
            "# ✅ Client Rating\n\n ### Client: <@" .. Executor.id .. ">\n\n### Speed: " ..Speed .. "/5 \n".. SpeedStars .."\n### Quality: " ..Quality .. "/5 \n\n".. QualityStars .."\n\n" .. ExtraDescription
            
            _G.PendingSubmissions[Executor.id] = {
                description = NewDescription,
                channelId = ClientRatingChannelID,
            }

            interaction:editReply({
                    embed = {
                        title = "📋 **Preview your rating submission: **\n",
                        description = NewDescription,
                        fields = {};
                    };
                    components = {
                        {
                            type = 1,
                            components = {
                                { type = 2, style = 3, label = "✅ Confirm", custom_id = "submit_confirm_" .. Executor.id },
                                { type = 2, style = 4, label = "❌ Cancel", custom_id = "submit_cancel_" .. Executor.id }
                            }
                        }
                    }
                })
        end;
    };

    {
        Data = {
            name = "startgiveaway",
            description = "Starts a Giveaway",
            default_member_permissions = "0",
            options = {
                {
                    name = "prize",
                    description = "The prize to give away",
                    type = 3,
                    required = true
                },
                {
                    name = "duration",
                    description = "Duration of the giveaway",
                    type = 3,
                    required = true
                },
            }
        };

        ---@param interaction Interaction
        OnRan = function(interaction, cmd, args)
            local Guild = interaction.guild
            local I = Guild.me
            local Executor = interaction.member

            if not tonumber(args.duration) then
                interaction:editReply("❌ **Please specify a valid duration.**")
            return end

            local Channel = interaction.channel
            local Message = interaction:getReply()

            interaction:editReply({
                embed = {
                    title = "📋 Preview Giveaway Submission \n",
                    description = "**Prize:** " .. args.prize .. "\n\n**Ends:** <t:" .. os.time() + tonumber(args.duration) .. ":R>\n\n**Hosted by:** <@" .. Executor.id .. ">",
                },
                components = {
                    {
                        type = 1,
                        components = {
                            { type = 2, style = 3, label = "✅ Start", custom_id = "giveaway_enter" },
                        }
                    }
                },
                epheremal = true,
            })

            _G.ActiveGiveaways[Message.id] = {
                guildId = Guild.id,
                channelId = Channel.id,
                messageId = Message.id,
                hostId = Executor.id,
                prize = args.prize,
                entrants = {},
                winners = args.winners or 1,
                EndTime = os.time() + tonumber(args.duration)
            };
        end;
    };

    {
        Data = {
            name = "sendverificationmessage",
            default_member_permissions = "0",
            description = "Sends the verification message in the verify channel.",
        };

        ---@param interaction Interaction
        OnRan = function(interaction, cmd, args)
            local Guild = interaction.guild
            local I = Guild.me
            local Executor = interaction.member

            local Channel = Guild:getChannel(VerifyChannelID)
            interaction:reply("**Loading...**")

            local VerifyButton = discordia.Button("verify")
                :label("✅ Verify")
                :style("success")

            local VerifyComponents = discordia.Components()
                :button(VerifyButton)

            local HasSucceeded, Callback = pcall (function()    
                Channel:sendComponents({
                    embed = {
                        title = "";
                        description = "# How to Verify? \nClick on the ✅ button below to verify! \n-# If it says ".. '"This interaction failed"'.. " then you can click on the ✅ reaction button below it to verify."
                    };
                }, VerifyComponents)
            end)

            if not HasSucceeded then
                interaction:editReply("❌ **Error occurred!** Callback:".. Callback)
            else
                interaction:editReply("✅ **Success!**")
            end
        end;
    };
}