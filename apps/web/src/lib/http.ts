import axios from 'axios';
import { GOV_API_BASE } from '@hyapi/shared';

export function makeClient(token: string) {
  return axios.create({
    baseURL: GOV_API_BASE,
    headers: { Authorization: `Bearer ${token}` }
  });
}
