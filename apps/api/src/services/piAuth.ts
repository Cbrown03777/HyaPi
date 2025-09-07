export async function verifyPiToken(bearer: string): Promise<{ userId:number; pi_address:string }> {
  // Dev token format: "dev <pi_address>:<userId>"
  if (!bearer.startsWith('dev ')) throw new Error('invalid token');
  const [addr, id] = bearer.slice(4).split(':');
  return { userId: Number(id ?? 1), pi_address: addr ?? 'pi_dev_address' };
}
 
