/**
 * Stand-in for firebase-admin's Messaging. Records every multicast and lets a
 * test mark tokens as stale.
 */
export function createFakeMessaging({ staleTokens = [] } = {}) {
  const sent = [];

  return {
    sent,
    async sendEachForMulticast(message) {
      sent.push(message);
      const responses = message.tokens.map((token) =>
        staleTokens.includes(token)
          ? {
              success: false,
              error: { code: 'messaging/registration-token-not-registered' },
            }
          : { success: true },
      );
      return { responses };
    },
  };
}
