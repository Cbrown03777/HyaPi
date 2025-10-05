--
-- PostgreSQL database dump
--

\restrict bALKNvqgKxU6O57xVLQ6GurtVXHgp0mFQZjbGraMQjQI3KkS3M1Cb4d3aLrkPfo

-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: liquidity_kind; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.liquidity_kind AS ENUM (
    'deposit',
    'withdraw',
    'rebalance_in',
    'rebalance_out',
    'fee',
    'yield'
);


ALTER TYPE public.liquidity_kind OWNER TO postgres;

--
-- Name: stakes_set_unlock_ts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.stakes_set_unlock_ts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.unlock_ts := NEW.start_ts + (NEW.lockup_weeks::int * INTERVAL '1 week');
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.stakes_set_unlock_ts() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._migrations (
    filename text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public._migrations OWNER TO postgres;

--
-- Name: allocation_basket_venues; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocation_basket_venues (
    basket_id text NOT NULL,
    venue_key text NOT NULL,
    basket_cap_bps integer
);


ALTER TABLE public.allocation_basket_venues OWNER TO postgres;

--
-- Name: allocation_baskets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocation_baskets (
    basket_id text NOT NULL,
    name text NOT NULL,
    description text,
    strategy_tag text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.allocation_baskets OWNER TO postgres;

--
-- Name: allocation_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocation_history (
    id integer NOT NULL,
    as_of timestamp with time zone DEFAULT now() NOT NULL,
    total_usd numeric,
    total_gross_apy double precision,
    total_net_apy double precision,
    baskets_json jsonb
);


ALTER TABLE public.allocation_history OWNER TO postgres;

--
-- Name: allocation_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.allocation_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.allocation_history_id_seq OWNER TO postgres;

--
-- Name: allocation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.allocation_history_id_seq OWNED BY public.allocation_history.id;


--
-- Name: allocation_targets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocation_targets (
    id integer NOT NULL,
    key text NOT NULL,
    weight_fraction numeric(9,6) NOT NULL,
    source text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    CONSTRAINT allocation_targets_source_check CHECK ((source = ANY (ARRAY['gov'::text, 'override'::text]))),
    CONSTRAINT allocation_targets_weight_fraction_check CHECK ((weight_fraction >= (0)::numeric))
);


ALTER TABLE public.allocation_targets OWNER TO postgres;

--
-- Name: allocation_targets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.allocation_targets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.allocation_targets_id_seq OWNER TO postgres;

--
-- Name: allocation_targets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.allocation_targets_id_seq OWNED BY public.allocation_targets.id;


--
-- Name: allocations_current; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocations_current (
    chain text NOT NULL,
    weight_fraction numeric(6,5) NOT NULL,
    updated_from_proposal bigint,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT allocations_current_chain_check CHECK ((chain = ANY (ARRAY['sui'::text, 'aptos'::text, 'cosmos'::text])))
);


ALTER TABLE public.allocations_current OWNER TO postgres;

--
-- Name: allocations_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.allocations_history (
    id bigint NOT NULL,
    chain text NOT NULL,
    weight_fraction numeric(6,5) NOT NULL,
    proposal_id bigint,
    effective_at timestamp with time zone DEFAULT now() NOT NULL,
    executed_at timestamp with time zone DEFAULT now(),
    CONSTRAINT allocations_history_chain_check CHECK ((chain = ANY (ARRAY['sui'::text, 'aptos'::text, 'cosmos'::text])))
);


ALTER TABLE public.allocations_history OWNER TO postgres;

--
-- Name: allocations_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.allocations_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.allocations_history_id_seq OWNER TO postgres;

--
-- Name: allocations_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.allocations_history_id_seq OWNED BY public.allocations_history.id;


--
-- Name: apy_tiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.apy_tiers (
    min_weeks integer NOT NULL,
    apy_bps integer NOT NULL,
    CONSTRAINT apy_tiers_apy_bps_check CHECK (((apy_bps >= 0) AND (apy_bps <= 5000)))
);


ALTER TABLE public.apy_tiers OWNER TO postgres;

--
-- Name: balances; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.balances (
    user_id bigint NOT NULL,
    hyapi_amount numeric(38,18) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.balances OWNER TO postgres;

--
-- Name: delegations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.delegations (
    id bigint NOT NULL,
    chain text NOT NULL,
    provider text NOT NULL,
    action text NOT NULL,
    amount numeric(38,6) NOT NULL,
    tx_ref text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.delegations OWNER TO postgres;

--
-- Name: delegations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.delegations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.delegations_id_seq OWNER TO postgres;

--
-- Name: delegations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.delegations_id_seq OWNED BY public.delegations.id;


--
-- Name: exchanges; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exchanges (
    id bigint NOT NULL,
    user_id bigint,
    src_asset text NOT NULL,
    dst_asset text NOT NULL,
    amount_src numeric(38,6) NOT NULL,
    amount_dst numeric(38,6) NOT NULL,
    rate numeric(38,12),
    provider text,
    tx_ref text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.exchanges OWNER TO postgres;

--
-- Name: exchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exchanges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exchanges_id_seq OWNER TO postgres;

--
-- Name: exchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exchanges_id_seq OWNED BY public.exchanges.id;


--
-- Name: gov_allocation_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_allocation_history (
    id bigint NOT NULL,
    proposal_id bigint,
    key text NOT NULL,
    weight_fraction numeric(10,8) NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    normalization numeric(10,8)
);


ALTER TABLE public.gov_allocation_history OWNER TO postgres;

--
-- Name: gov_allocation_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gov_allocation_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gov_allocation_history_id_seq OWNER TO postgres;

--
-- Name: gov_allocation_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gov_allocation_history_id_seq OWNED BY public.gov_allocation_history.id;


--
-- Name: gov_execution_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_execution_queue (
    id bigint NOT NULL,
    proposal_id bigint,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    execute_not_before timestamp with time zone NOT NULL,
    executed_at timestamp with time zone
);


ALTER TABLE public.gov_execution_queue OWNER TO postgres;

--
-- Name: gov_execution_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gov_execution_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gov_execution_queue_id_seq OWNER TO postgres;

--
-- Name: gov_execution_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gov_execution_queue_id_seq OWNED BY public.gov_execution_queue.id;


--
-- Name: gov_params; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_params (
    id smallint DEFAULT 1 NOT NULL,
    quorum_bps integer DEFAULT 2000 NOT NULL,
    pass_threshold_bps integer DEFAULT 5000 NOT NULL,
    min_proposer_power_bps integer DEFAULT 100 NOT NULL,
    proposal_fee_pi numeric(38,18) DEFAULT 0 NOT NULL,
    vote_duration_days integer DEFAULT 7 NOT NULL,
    epoch_cadence text DEFAULT 'quarterly'::text NOT NULL,
    max_chain_weight_bps integer DEFAULT 4000 NOT NULL,
    min_pi_buffer_bps integer DEFAULT 1000 NOT NULL
);


ALTER TABLE public.gov_params OWNER TO postgres;

--
-- Name: gov_power_snapshot_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_power_snapshot_items (
    snapshot_id bigint NOT NULL,
    user_id bigint NOT NULL,
    voting_power numeric(38,18) NOT NULL
);


ALTER TABLE public.gov_power_snapshot_items OWNER TO postgres;

--
-- Name: gov_power_snapshots; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_power_snapshots (
    id bigint NOT NULL,
    snap_ts timestamp with time zone NOT NULL,
    total_hyapi_supply numeric(38,18) NOT NULL,
    notes text
);


ALTER TABLE public.gov_power_snapshots OWNER TO postgres;

--
-- Name: gov_power_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gov_power_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gov_power_snapshots_id_seq OWNER TO postgres;

--
-- Name: gov_power_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gov_power_snapshots_id_seq OWNED BY public.gov_power_snapshots.id;


--
-- Name: gov_proposal_allocations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_proposal_allocations (
    proposal_id bigint NOT NULL,
    key text NOT NULL,
    weight_fraction numeric(6,5) NOT NULL
);


ALTER TABLE public.gov_proposal_allocations OWNER TO postgres;

--
-- Name: gov_proposals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_proposals (
    id bigint NOT NULL,
    title text NOT NULL,
    description text,
    proposer_user_id bigint,
    snapshot_id bigint,
    start_ts timestamp with time zone NOT NULL,
    end_ts timestamp with time zone NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    quorum_met boolean DEFAULT false,
    passed boolean DEFAULT false,
    total_votes_power numeric(78,0) DEFAULT 0,
    updated_at timestamp with time zone DEFAULT now(),
    executed_at timestamp with time zone
);


ALTER TABLE public.gov_proposals OWNER TO postgres;

--
-- Name: gov_proposals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gov_proposals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gov_proposals_id_seq OWNER TO postgres;

--
-- Name: gov_proposals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gov_proposals_id_seq OWNED BY public.gov_proposals.id;


--
-- Name: gov_tallies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_tallies (
    proposal_id bigint NOT NULL,
    for_power numeric(78,0) DEFAULT 0 NOT NULL,
    against_power numeric(78,0) DEFAULT 0 NOT NULL,
    abstain_power numeric(78,0) DEFAULT 0 NOT NULL
);


ALTER TABLE public.gov_tallies OWNER TO postgres;

--
-- Name: gov_votes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gov_votes (
    proposal_id bigint NOT NULL,
    user_id bigint NOT NULL,
    support smallint NOT NULL,
    voting_power numeric(78,0) NOT NULL,
    cast_at timestamp with time zone DEFAULT now() NOT NULL,
    power numeric(78,0),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT gov_votes_support_check CHECK ((support = ANY (ARRAY[0, 1, 2])))
);


ALTER TABLE public.gov_votes OWNER TO postgres;

--
-- Name: governance_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.governance_locks (
    user_id text NOT NULL,
    term_weeks integer NOT NULL,
    locked_at timestamp with time zone DEFAULT now() NOT NULL,
    unlock_at timestamp with time zone NOT NULL,
    tx_url text,
    CONSTRAINT governance_locks_term_weeks_check CHECK ((term_weeks = ANY (ARRAY[26, 52, 104])))
);


ALTER TABLE public.governance_locks OWNER TO postgres;

--
-- Name: liquidity_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.liquidity_events (
    id bigint NOT NULL,
    kind public.liquidity_kind NOT NULL,
    amount_usd numeric(20,6) NOT NULL,
    venue_key text,
    tx_ref text,
    idem_key text,
    plan_version bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.liquidity_events OWNER TO postgres;

--
-- Name: liquidity_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.liquidity_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.liquidity_events_id_seq OWNER TO postgres;

--
-- Name: liquidity_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.liquidity_events_id_seq OWNED BY public.liquidity_events.id;


--
-- Name: nav_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nav_history (
    d date NOT NULL,
    pps numeric NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT nav_history_pps_check CHECK ((pps > (0)::numeric))
);


ALTER TABLE public.nav_history OWNER TO postgres;

--
-- Name: pi_identities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pi_identities (
    uid text NOT NULL,
    user_id bigint NOT NULL,
    username text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pi_identities OWNER TO postgres;

--
-- Name: pi_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pi_payments (
    id bigint NOT NULL,
    pi_payment_id text NOT NULL,
    direction text NOT NULL,
    uid text NOT NULL,
    amount_pi numeric(24,6) DEFAULT 0 NOT NULL,
    status text NOT NULL,
    txid text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pi_payments_direction_check CHECK ((direction = ANY (ARRAY['U2A'::text, 'A2U'::text]))),
    CONSTRAINT pi_payments_status_check CHECK ((status = ANY (ARRAY['created'::text, 'approved'::text, 'completed'::text, 'failed'::text])))
);


ALTER TABLE public.pi_payments OWNER TO postgres;

--
-- Name: pi_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pi_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pi_payments_id_seq OWNER TO postgres;

--
-- Name: pi_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pi_payments_id_seq OWNED BY public.pi_payments.id;


--
-- Name: planned_actions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.planned_actions (
    id bigint NOT NULL,
    kind text NOT NULL,
    venue_key text NOT NULL,
    amount_usd numeric(20,6) NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    idem_key text,
    CONSTRAINT planned_actions_amount_usd_check CHECK ((amount_usd > (0)::numeric)),
    CONSTRAINT planned_actions_kind_check CHECK ((kind = ANY (ARRAY['supply'::text, 'redeem'::text]))),
    CONSTRAINT planned_actions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'confirmed'::text, 'failed'::text, 'canceled'::text])))
);


ALTER TABLE public.planned_actions OWNER TO postgres;

--
-- Name: planned_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.planned_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.planned_actions_id_seq OWNER TO postgres;

--
-- Name: planned_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.planned_actions_id_seq OWNED BY public.planned_actions.id;


--
-- Name: pps_series; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pps_series (
    id bigint NOT NULL,
    as_of_date date NOT NULL,
    pps_1e18 numeric(78,0) NOT NULL,
    fees_1e18 numeric(78,0) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.pps_series OWNER TO postgres;

--
-- Name: pps_series_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pps_series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pps_series_id_seq OWNER TO postgres;

--
-- Name: pps_series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pps_series_id_seq OWNED BY public.pps_series.id;


--
-- Name: proposal_status_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proposal_status_history (
    id bigint NOT NULL,
    proposal_id bigint NOT NULL,
    from_status text,
    to_status text NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.proposal_status_history OWNER TO postgres;

--
-- Name: proposal_status_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.proposal_status_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.proposal_status_history_id_seq OWNER TO postgres;

--
-- Name: proposal_status_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.proposal_status_history_id_seq OWNED BY public.proposal_status_history.id;


--
-- Name: rebalance_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rebalance_plans (
    id bigint NOT NULL,
    tvl_usd numeric(24,6) DEFAULT 0 NOT NULL,
    actions_json jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    buffer_usd numeric(24,6) DEFAULT 0 NOT NULL,
    drift_bps integer DEFAULT 0 NOT NULL,
    target_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'planned'::text NOT NULL
);


ALTER TABLE public.rebalance_plans OWNER TO postgres;

--
-- Name: rebalance_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rebalance_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rebalance_plans_id_seq OWNER TO postgres;

--
-- Name: rebalance_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rebalance_plans_id_seq OWNED BY public.rebalance_plans.id;


--
-- Name: redemptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.redemptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    stake_id bigint,
    amount_pi numeric(38,6) NOT NULL,
    eta_ts timestamp with time zone,
    needs_unstake boolean DEFAULT false NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT redemptions_amount_pi_check CHECK ((amount_pi > (0)::numeric))
);


ALTER TABLE public.redemptions OWNER TO postgres;

--
-- Name: redemptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.redemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.redemptions_id_seq OWNER TO postgres;

--
-- Name: redemptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.redemptions_id_seq OWNED BY public.redemptions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: stakes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stakes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    amount_pi numeric(38,6) NOT NULL,
    lockup_weeks integer NOT NULL,
    apy_bps integer DEFAULT 500 NOT NULL,
    init_fee_bps integer DEFAULT 0 NOT NULL,
    early_exit_fee_bps integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    start_ts timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    unlock_ts timestamp with time zone
);


ALTER TABLE public.stakes OWNER TO postgres;

--
-- Name: stakes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.stakes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stakes_id_seq OWNER TO postgres;

--
-- Name: stakes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.stakes_id_seq OWNED BY public.stakes.id;


--
-- Name: treasury; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.treasury (
    id boolean DEFAULT true NOT NULL,
    buffer_pi numeric(38,6) DEFAULT 0 NOT NULL,
    last_updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT treasury_id_check CHECK (id)
);


ALTER TABLE public.treasury OWNER TO postgres;

--
-- Name: tvl_buffer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tvl_buffer (
    id smallint DEFAULT 1 NOT NULL,
    buffer_usd numeric(20,6) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tvl_buffer OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    pi_address text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    kyc_status text DEFAULT 'unknown'::text
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: v_apy_for_lock; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_apy_for_lock AS
 SELECT w AS lockup_weeks,
    ( SELECT t.apy_bps
           FROM public.apy_tiers t
          WHERE (t.min_weeks <= g.w)
          ORDER BY t.min_weeks DESC
         LIMIT 1) AS apy_bps
   FROM generate_series(0, 104) g(w);


ALTER VIEW public.v_apy_for_lock OWNER TO postgres;

--
-- Name: v_pps_latest; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_pps_latest AS
 SELECT id,
    as_of_date,
    pps_1e18,
    fees_1e18,
    created_at
   FROM public.pps_series p
  ORDER BY as_of_date DESC
 LIMIT 1;


ALTER VIEW public.v_pps_latest OWNER TO postgres;

--
-- Name: v_redemption_queue; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_redemption_queue AS
 SELECT id,
    user_id,
    stake_id,
    amount_pi,
    eta_ts,
    needs_unstake,
    status,
    created_at,
    updated_at,
        CASE
            WHEN needs_unstake THEN 'queued'::text
            WHEN ((status = 'pending'::text) AND (eta_ts IS NULL)) THEN 'instant'::text
            ELSE 'pending'::text
        END AS path
   FROM public.redemptions r
  WHERE (status = ANY (ARRAY['pending'::text, 'processing'::text]))
  ORDER BY COALESCE(eta_ts, now()), created_at;


ALTER VIEW public.v_redemption_queue OWNER TO postgres;

--
-- Name: v_user_portfolio; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_user_portfolio AS
 SELECT u.id AS user_id,
    COALESCE(b.hyapi_amount, (0)::numeric) AS hyapi_amount,
    l.pps_1e18,
    ((COALESCE(b.hyapi_amount, (0)::numeric) * ((l.pps_1e18)::numeric / 1000000000000000000.0)))::numeric(38,6) AS effective_pi_value
   FROM ((public.users u
     LEFT JOIN public.balances b ON ((b.user_id = u.id)))
     CROSS JOIN public.v_pps_latest l);


ALTER VIEW public.v_user_portfolio OWNER TO postgres;

--
-- Name: venue_balances_pi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venue_balances_pi (
    venue text NOT NULL,
    deployed_pi numeric(24,6) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.venue_balances_pi OWNER TO postgres;

--
-- Name: venue_holdings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venue_holdings (
    key text NOT NULL,
    usd_notional numeric(24,6) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.venue_holdings OWNER TO postgres;

--
-- Name: venue_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venue_rates (
    id bigint NOT NULL,
    key text NOT NULL,
    base_apr numeric(12,8) NOT NULL,
    as_of timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    venue text,
    chain text,
    market text,
    base_apy double precision,
    reward_apr double precision,
    reward_apy double precision,
    source text,
    fetched_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.venue_rates OWNER TO postgres;

--
-- Name: venue_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venue_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venue_rates_id_seq OWNER TO postgres;

--
-- Name: venue_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venue_rates_id_seq OWNED BY public.venue_rates.id;


--
-- Name: allocation_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_history ALTER COLUMN id SET DEFAULT nextval('public.allocation_history_id_seq'::regclass);


--
-- Name: allocation_targets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_targets ALTER COLUMN id SET DEFAULT nextval('public.allocation_targets_id_seq'::regclass);


--
-- Name: allocations_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations_history ALTER COLUMN id SET DEFAULT nextval('public.allocations_history_id_seq'::regclass);


--
-- Name: delegations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delegations ALTER COLUMN id SET DEFAULT nextval('public.delegations_id_seq'::regclass);


--
-- Name: exchanges id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exchanges ALTER COLUMN id SET DEFAULT nextval('public.exchanges_id_seq'::regclass);


--
-- Name: gov_allocation_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_allocation_history ALTER COLUMN id SET DEFAULT nextval('public.gov_allocation_history_id_seq'::regclass);


--
-- Name: gov_execution_queue id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_execution_queue ALTER COLUMN id SET DEFAULT nextval('public.gov_execution_queue_id_seq'::regclass);


--
-- Name: gov_power_snapshots id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_power_snapshots ALTER COLUMN id SET DEFAULT nextval('public.gov_power_snapshots_id_seq'::regclass);


--
-- Name: gov_proposals id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_proposals ALTER COLUMN id SET DEFAULT nextval('public.gov_proposals_id_seq'::regclass);


--
-- Name: liquidity_events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liquidity_events ALTER COLUMN id SET DEFAULT nextval('public.liquidity_events_id_seq'::regclass);


--
-- Name: pi_payments id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pi_payments ALTER COLUMN id SET DEFAULT nextval('public.pi_payments_id_seq'::regclass);


--
-- Name: planned_actions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.planned_actions ALTER COLUMN id SET DEFAULT nextval('public.planned_actions_id_seq'::regclass);


--
-- Name: pps_series id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pps_series ALTER COLUMN id SET DEFAULT nextval('public.pps_series_id_seq'::regclass);


--
-- Name: proposal_status_history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proposal_status_history ALTER COLUMN id SET DEFAULT nextval('public.proposal_status_history_id_seq'::regclass);


--
-- Name: rebalance_plans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rebalance_plans ALTER COLUMN id SET DEFAULT nextval('public.rebalance_plans_id_seq'::regclass);


--
-- Name: redemptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions ALTER COLUMN id SET DEFAULT nextval('public.redemptions_id_seq'::regclass);


--
-- Name: stakes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stakes ALTER COLUMN id SET DEFAULT nextval('public.stakes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: venue_rates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venue_rates ALTER COLUMN id SET DEFAULT nextval('public.venue_rates_id_seq'::regclass);


--
-- Name: _migrations _migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._migrations
    ADD CONSTRAINT _migrations_pkey PRIMARY KEY (filename);


--
-- Name: allocation_basket_venues allocation_basket_venues_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_basket_venues
    ADD CONSTRAINT allocation_basket_venues_pkey PRIMARY KEY (basket_id, venue_key);


--
-- Name: allocation_baskets allocation_baskets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_baskets
    ADD CONSTRAINT allocation_baskets_pkey PRIMARY KEY (basket_id);


--
-- Name: allocation_history allocation_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_history
    ADD CONSTRAINT allocation_history_pkey PRIMARY KEY (id);


--
-- Name: allocation_targets allocation_targets_key_source_applied_at_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_targets
    ADD CONSTRAINT allocation_targets_key_source_applied_at_key UNIQUE (key, source, applied_at);


--
-- Name: allocation_targets allocation_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_targets
    ADD CONSTRAINT allocation_targets_pkey PRIMARY KEY (id);


--
-- Name: allocations_current allocations_current_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations_current
    ADD CONSTRAINT allocations_current_pkey PRIMARY KEY (chain);


--
-- Name: allocations_history allocations_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations_history
    ADD CONSTRAINT allocations_history_pkey PRIMARY KEY (id);


--
-- Name: allocations_history allocations_history_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations_history
    ADD CONSTRAINT allocations_history_unique UNIQUE (proposal_id, chain);


--
-- Name: apy_tiers apy_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.apy_tiers
    ADD CONSTRAINT apy_tiers_pkey PRIMARY KEY (min_weeks);


--
-- Name: balances balances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT balances_pkey PRIMARY KEY (user_id);


--
-- Name: delegations delegations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.delegations
    ADD CONSTRAINT delegations_pkey PRIMARY KEY (id);


--
-- Name: exchanges exchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exchanges
    ADD CONSTRAINT exchanges_pkey PRIMARY KEY (id);


--
-- Name: gov_allocation_history gov_allocation_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_allocation_history
    ADD CONSTRAINT gov_allocation_history_pkey PRIMARY KEY (id);


--
-- Name: gov_execution_queue gov_execution_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_execution_queue
    ADD CONSTRAINT gov_execution_queue_pkey PRIMARY KEY (id);


--
-- Name: gov_execution_queue gov_execution_queue_proposal_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_execution_queue
    ADD CONSTRAINT gov_execution_queue_proposal_id_key UNIQUE (proposal_id);


--
-- Name: gov_params gov_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_params
    ADD CONSTRAINT gov_params_pkey PRIMARY KEY (id);


--
-- Name: gov_power_snapshot_items gov_power_snapshot_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_power_snapshot_items
    ADD CONSTRAINT gov_power_snapshot_items_pkey PRIMARY KEY (snapshot_id, user_id);


--
-- Name: gov_power_snapshots gov_power_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_power_snapshots
    ADD CONSTRAINT gov_power_snapshots_pkey PRIMARY KEY (id);


--
-- Name: gov_proposal_allocations gov_proposal_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_proposal_allocations
    ADD CONSTRAINT gov_proposal_allocations_pkey PRIMARY KEY (proposal_id, key);


--
-- Name: gov_proposals gov_proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_proposals
    ADD CONSTRAINT gov_proposals_pkey PRIMARY KEY (id);


--
-- Name: gov_tallies gov_tallies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_tallies
    ADD CONSTRAINT gov_tallies_pkey PRIMARY KEY (proposal_id);


--
-- Name: gov_votes gov_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_votes
    ADD CONSTRAINT gov_votes_pkey PRIMARY KEY (proposal_id, user_id);


--
-- Name: gov_votes gov_votes_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_votes
    ADD CONSTRAINT gov_votes_unique UNIQUE (proposal_id, user_id);


--
-- Name: governance_locks governance_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.governance_locks
    ADD CONSTRAINT governance_locks_pkey PRIMARY KEY (user_id);


--
-- Name: liquidity_events liquidity_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liquidity_events
    ADD CONSTRAINT liquidity_events_pkey PRIMARY KEY (id);


--
-- Name: nav_history nav_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nav_history
    ADD CONSTRAINT nav_history_pkey PRIMARY KEY (d);


--
-- Name: pi_identities pi_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pi_identities
    ADD CONSTRAINT pi_identities_pkey PRIMARY KEY (uid);


--
-- Name: pi_payments pi_payments_pi_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pi_payments
    ADD CONSTRAINT pi_payments_pi_payment_id_key UNIQUE (pi_payment_id);


--
-- Name: pi_payments pi_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pi_payments
    ADD CONSTRAINT pi_payments_pkey PRIMARY KEY (id);


--
-- Name: planned_actions planned_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.planned_actions
    ADD CONSTRAINT planned_actions_pkey PRIMARY KEY (id);


--
-- Name: pps_series pps_series_as_of_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pps_series
    ADD CONSTRAINT pps_series_as_of_date_key UNIQUE (as_of_date);


--
-- Name: pps_series pps_series_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pps_series
    ADD CONSTRAINT pps_series_pkey PRIMARY KEY (id);


--
-- Name: proposal_status_history proposal_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proposal_status_history
    ADD CONSTRAINT proposal_status_history_pkey PRIMARY KEY (id);


--
-- Name: rebalance_plans rebalance_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rebalance_plans
    ADD CONSTRAINT rebalance_plans_pkey PRIMARY KEY (id);


--
-- Name: redemptions redemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: stakes stakes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stakes
    ADD CONSTRAINT stakes_pkey PRIMARY KEY (id);


--
-- Name: treasury treasury_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.treasury
    ADD CONSTRAINT treasury_pkey PRIMARY KEY (id);


--
-- Name: tvl_buffer tvl_buffer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tvl_buffer
    ADD CONSTRAINT tvl_buffer_pkey PRIMARY KEY (id);


--
-- Name: users users_pi_address_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pi_address_key UNIQUE (pi_address);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: venue_balances_pi venue_balances_pi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venue_balances_pi
    ADD CONSTRAINT venue_balances_pi_pkey PRIMARY KEY (venue);


--
-- Name: venue_holdings venue_holdings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venue_holdings
    ADD CONSTRAINT venue_holdings_pkey PRIMARY KEY (key);


--
-- Name: venue_rates venue_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venue_rates
    ADD CONSTRAINT venue_rates_pkey PRIMARY KEY (id);


--
-- Name: allocation_history_asof_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX allocation_history_asof_idx ON public.allocation_history USING btree (as_of DESC);


--
-- Name: allocation_targets_source_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX allocation_targets_source_idx ON public.allocation_targets USING btree (source, applied_at DESC);


--
-- Name: idx_allocation_targets_key_source; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_allocation_targets_key_source ON public.allocation_targets USING btree (key, source);


--
-- Name: idx_allocation_targets_source_applied_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_allocation_targets_source_applied_at ON public.allocation_targets USING btree (source, applied_at DESC);


--
-- Name: idx_allocations_current_chain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_allocations_current_chain ON public.allocations_current USING btree (chain);


--
-- Name: idx_delegations_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_delegations_action ON public.delegations USING btree (action);


--
-- Name: idx_delegations_chain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_delegations_chain ON public.delegations USING btree (chain);


--
-- Name: idx_exchanges_assets; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exchanges_assets ON public.exchanges USING btree (src_asset, dst_asset);


--
-- Name: idx_exchanges_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exchanges_user ON public.exchanges USING btree (user_id);


--
-- Name: idx_gov_alloc_hist_applied_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gov_alloc_hist_applied_at ON public.gov_allocation_history USING btree (applied_at DESC);


--
-- Name: idx_gov_alloc_hist_proposal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_gov_alloc_hist_proposal ON public.gov_allocation_history USING btree (proposal_id);


--
-- Name: idx_liq_events_kind_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_liq_events_kind_created_at ON public.liquidity_events USING btree (kind, created_at DESC);


--
-- Name: idx_nav_history_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_nav_history_created_at ON public.nav_history USING btree (created_at);


--
-- Name: idx_pi_payments_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pi_payments_uid ON public.pi_payments USING btree (uid);


--
-- Name: idx_planned_actions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_planned_actions_status ON public.planned_actions USING btree (status, created_at);


--
-- Name: idx_power_items_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_power_items_user ON public.gov_power_snapshot_items USING btree (user_id);


--
-- Name: idx_proposals_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_proposals_status ON public.gov_proposals USING btree (status, end_ts);


--
-- Name: idx_rebalance_plans_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_rebalance_plans_created_at ON public.rebalance_plans USING btree (created_at DESC);


--
-- Name: idx_redemptions_eta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_eta ON public.redemptions USING btree (eta_ts);


--
-- Name: idx_redemptions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_status ON public.redemptions USING btree (status);


--
-- Name: idx_redemptions_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_redemptions_user ON public.redemptions USING btree (user_id);


--
-- Name: idx_stakes_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stakes_status ON public.stakes USING btree (status);


--
-- Name: idx_stakes_unlock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stakes_unlock ON public.stakes USING btree (unlock_ts);


--
-- Name: idx_stakes_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stakes_user ON public.stakes USING btree (user_id);


--
-- Name: idx_venue_rates_key_ts; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venue_rates_key_ts ON public.venue_rates USING btree (key, as_of DESC);


--
-- Name: idx_venue_rates_lookup; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venue_rates_lookup ON public.venue_rates USING btree (venue, chain, market, fetched_at DESC);


--
-- Name: idx_venue_rates_vcm_fetch; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_venue_rates_vcm_fetch ON public.venue_rates USING btree (venue, chain, market, fetched_at DESC);


--
-- Name: idx_votes_by_proposal; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_votes_by_proposal ON public.gov_votes USING btree (proposal_id);


--
-- Name: uq_liq_events_idem_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_liq_events_idem_key ON public.liquidity_events USING btree (idem_key) WHERE (idem_key IS NOT NULL);


--
-- Name: uq_planned_actions_idem_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_planned_actions_idem_key ON public.planned_actions USING btree (idem_key) WHERE (idem_key IS NOT NULL);


--
-- Name: stakes stakes_unlock_ts_bi; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER stakes_unlock_ts_bi BEFORE INSERT OR UPDATE OF start_ts, lockup_weeks ON public.stakes FOR EACH ROW EXECUTE FUNCTION public.stakes_set_unlock_ts();


--
-- Name: allocation_basket_venues allocation_basket_venues_basket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocation_basket_venues
    ADD CONSTRAINT allocation_basket_venues_basket_id_fkey FOREIGN KEY (basket_id) REFERENCES public.allocation_baskets(basket_id) ON DELETE CASCADE;


--
-- Name: allocations_current allocations_current_updated_from_proposal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations_current
    ADD CONSTRAINT allocations_current_updated_from_proposal_fkey FOREIGN KEY (updated_from_proposal) REFERENCES public.gov_proposals(id);


--
-- Name: allocations_history allocations_history_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.allocations_history
    ADD CONSTRAINT allocations_history_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id);


--
-- Name: balances balances_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.balances
    ADD CONSTRAINT balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: exchanges exchanges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exchanges
    ADD CONSTRAINT exchanges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: gov_allocation_history gov_allocation_history_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_allocation_history
    ADD CONSTRAINT gov_allocation_history_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id) ON DELETE CASCADE;


--
-- Name: gov_execution_queue gov_execution_queue_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_execution_queue
    ADD CONSTRAINT gov_execution_queue_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id) ON DELETE CASCADE;


--
-- Name: gov_power_snapshot_items gov_power_snapshot_items_snapshot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_power_snapshot_items
    ADD CONSTRAINT gov_power_snapshot_items_snapshot_id_fkey FOREIGN KEY (snapshot_id) REFERENCES public.gov_power_snapshots(id) ON DELETE CASCADE;


--
-- Name: gov_power_snapshot_items gov_power_snapshot_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_power_snapshot_items
    ADD CONSTRAINT gov_power_snapshot_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: gov_proposal_allocations gov_proposal_allocations_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_proposal_allocations
    ADD CONSTRAINT gov_proposal_allocations_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id) ON DELETE CASCADE;


--
-- Name: gov_proposals gov_proposals_proposer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_proposals
    ADD CONSTRAINT gov_proposals_proposer_user_id_fkey FOREIGN KEY (proposer_user_id) REFERENCES public.users(id);


--
-- Name: gov_proposals gov_proposals_snapshot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_proposals
    ADD CONSTRAINT gov_proposals_snapshot_id_fkey FOREIGN KEY (snapshot_id) REFERENCES public.gov_power_snapshots(id);


--
-- Name: gov_tallies gov_tallies_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_tallies
    ADD CONSTRAINT gov_tallies_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id) ON DELETE CASCADE;


--
-- Name: gov_votes gov_votes_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_votes
    ADD CONSTRAINT gov_votes_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id) ON DELETE CASCADE;


--
-- Name: gov_votes gov_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gov_votes
    ADD CONSTRAINT gov_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: pi_identities pi_identities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pi_identities
    ADD CONSTRAINT pi_identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: proposal_status_history proposal_status_history_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proposal_status_history
    ADD CONSTRAINT proposal_status_history_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.gov_proposals(id) ON DELETE CASCADE;


--
-- Name: redemptions redemptions_stake_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_stake_id_fkey FOREIGN KEY (stake_id) REFERENCES public.stakes(id) ON DELETE SET NULL;


--
-- Name: redemptions redemptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.redemptions
    ADD CONSTRAINT redemptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: stakes stakes_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stakes
    ADD CONSTRAINT stakes_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict bALKNvqgKxU6O57xVLQ6GurtVXHgp0mFQZjbGraMQjQI3KkS3M1Cb4d3aLrkPfo

