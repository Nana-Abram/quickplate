/**
 * Stand-in for firebase-admin's Auth. A token of the form `token-<uid>` is
 * valid for that uid; anything else is rejected.
 */
export function createFakeAuth() {
  return {
    async verifyIdToken(token) {
      if (!token.startsWith('token-')) {
        throw new Error('auth/argument-error');
      }
      return { uid: token.slice('token-'.length) };
    },
  };
}

export const bearer = (uid) => ({ Authorization: `Bearer token-${uid}` });
