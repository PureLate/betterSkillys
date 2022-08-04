﻿using CA.Extensions.Concurrent;
using common;
using System.Linq;
using wServer.core;
using wServer.core.worlds.logic;
using wServer.networking;

namespace wServer.core.net.handlers
{
    internal class GuildRemoveHandler : IMessageHandler
    {
        public override PacketId MessageId => PacketId.GUILDREMOVE;

        public override void Handle(Client client, NReader rdr, ref TickTime tickTime)
        {
            var name = rdr.ReadUTF();
            if (client.Player == null || client?.Player?.World is TestWorld)
                return;

            var srcPlayer = client.Player;
            var manager = client.CoreServerManager;

            // if resigning
            if (client.Account.Name.Equals(name))
            {
                // chat needs to be done before removal so we can use
                // srcPlayer as a source for guild info
                manager.ChatManager.Guild(srcPlayer, srcPlayer.Name + " has left the guild.");

                if (!manager.Database.RemoveFromGuild(client.Account))
                {
                    srcPlayer.SendError("Guild not found.");
                    return;
                }

                srcPlayer.Guild = "";
                srcPlayer.GuildRank = 0;

                return;
            }

            // get target account id
            var targetAccId = client.CoreServerManager.Database.ResolveId(name);
            if (targetAccId == 0)
            {
                client.Player.SendError("Player not found");
                return;
            }

            // find target player (if connected)
            var targetClient = client.CoreServerManager.ConnectionManager.Clients
                .KeyWhereAsParallel(_ => _.Account != null && _.Account.AccountId == targetAccId).FirstOrDefault();

            // try to remove connected member
            if (targetClient != null)
            {
                if (client.Account.GuildRank >= 20 &&
                    client.Account.GuildId == targetClient.Account.GuildId &&
                    client.Account.GuildRank > targetClient.Account.GuildRank)
                {
                    var targetPlayer = targetClient.Player;

                    if (!manager.Database.RemoveFromGuild(targetClient.Account))
                    {
                        srcPlayer.SendError("Guild not found.");
                        return;
                    }

                    targetPlayer.Guild = "";
                    targetPlayer.GuildRank = 0;

                    manager.ChatManager.Guild(srcPlayer, targetPlayer.Name + " has been kicked from the guild by " + srcPlayer.Name);
                    targetPlayer.SendInfo("You have been kicked from the guild.");
                    return;
                }

                srcPlayer.SendError("Can't remove member. Insufficient privileges.");
                return;
            }

            // try to remove member via database
            var targetAccount = manager.Database.GetAccount(targetAccId);

            if (client.Account.GuildRank >= 20 &&
                client.Account.GuildId == targetAccount.GuildId &&
                client.Account.GuildRank > targetAccount.GuildRank)
            {
                if (!manager.Database.RemoveFromGuild(targetAccount))
                {
                    srcPlayer.SendError("Guild not found.");
                    return;
                }

                manager.ChatManager.Guild(srcPlayer, targetAccount.Name + " has been kicked from the guild by " + srcPlayer.Name);
                manager.ChatManager.SendInfo(targetAccId, "You have been kicked from the guild.");
                return;
            }

            srcPlayer.SendError("Can't remove member. Insufficient privileges.");
        }
    }
}