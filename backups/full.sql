--
-- PostgreSQL database dump
--

\restrict mUBfqcwnEZfakXjC5l8aKKHGJnZVRT4mYeuz5BgUVTVCVStL5OSwVCeU7TKdPvN

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
-- Data for Name: _migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._migrations (filename, applied_at) FROM stdin;
0001_init.sql	2025-09-07 20:55:24.152615+00
0002_staking.sql	2025-09-07 21:07:05.413588+00
0003_redemptions.sql	2025-09-07 21:07:05.441717+00
0004_pps.sql	2025-09-07 21:07:05.447015+00
0005_exchanges.sql	2025-09-07 21:07:05.451641+00
0006_views.sql	2025-09-07 21:07:05.457501+00
0010_pi_payments.sql	2025-09-07 21:07:05.463984+00
0011_alloc.sql	2025-09-07 21:07:05.466574+00
0012_rebalance_plan_upgrade.sql	2025-09-07 21:07:05.469503+00
0013_venue_rates.sql	2025-09-07 23:28:14.586915+00
0013_venue_rates_upgrade.sql	2025-09-07 23:28:14.639293+00
0014_allocation_history.sql	2025-09-07 23:28:14.652468+00
0015_allocation_targets.sql	2025-09-07 23:28:14.675991+00
0016_gov_dynamic_keys.sql	2025-09-08 01:15:13.669656+00
0017_gov_allocation_history.sql	2025-09-09 22:56:55.412215+00
0018_alloc_targets_indexes.sql	2025-09-09 23:00:19.518212+00
0019_alloc_buffer_baskets.sql	2025-09-10 17:46:38.804862+00
0020_planned_actions.sql	2025-09-11 00:35:45.060797+00
0021_planned_actions_idem.sql	2025-09-11 00:41:22.169922+00
\.


--
-- Data for Name: allocation_basket_venues; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocation_basket_venues (basket_id, venue_key, basket_cap_bps) FROM stdin;
\.


--
-- Data for Name: allocation_baskets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocation_baskets (basket_id, name, description, strategy_tag, created_at) FROM stdin;
\.


--
-- Data for Name: allocation_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocation_history (id, as_of, total_usd, total_gross_apy, total_net_apy, baskets_json) FROM stdin;
1	2025-09-07 23:46:34.765+00	750000	0.09876441584448992	0.08888797426004093	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.03190975509340501, "baseApr": 0.034842880318032, "grossApy": 0.03545528343711668, "rewardApr": 0, "dailyNetUsd": 25.782865945589226}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03900197242175063, "baseApr": 0.04242528186899104, "grossApy": 0.043335524913056256, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.03190975509340501, "baseApr": 0.034842880318032, "grossApy": 0.03545528343711668, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
2	2025-09-08 00:02:24.414+00	750000	0.09906586638824046	0.08915927974941641	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.03259970770106309, "baseApr": 0.035583041969424, "grossApy": 0.03622189744562565, "rewardApr": 0, "dailyNetUsd": 26.340342978552556}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03911400906341327, "baseApr": 0.04254460323533279, "grossApy": 0.04346001007045919, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.03259970770106309, "baseApr": 0.035583041969424, "grossApy": 0.03622189744562565, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
3	2025-09-08 00:17:47.802+00	750000	0.09912862203702186	0.08921575983331967	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.03274334129011985, "baseApr": 0.035737059346848, "grossApy": 0.03638149032235538, "rewardApr": 0, "dailyNetUsd": 26.45639794547706}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.039098933126147095, "baseApr": 0.04252854787348793, "grossApy": 0.04344325902905233, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.03274334129011985, "baseApr": 0.035737059346848, "grossApy": 0.03638149032235538, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
4	2025-09-08 00:54:39.203+00	750000	0.09858146686280635	0.08872332017652572	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.03149102595325981, "baseApr": 0.034393413015504, "grossApy": 0.034990028836955345, "rewardApr": 0, "dailyNetUsd": 25.444535636996328}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.039114965443560745, "baseApr": 0.04254562173911657, "grossApy": 0.043461072715067495, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.03149102595325981, "baseApr": 0.034393413015504, "grossApy": 0.034990028836955345, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
5	2025-09-08 01:14:12.019+00	750000	0.09858146686280635	0.08872332017652572	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.03149102595325981, "baseApr": 0.034393413015504, "grossApy": 0.034990028836955345, "rewardApr": 0, "dailyNetUsd": 25.444535636996328}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.039064093996098226, "baseApr": 0.042491444398326444, "grossApy": 0.043404548884553584, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.03149102595325981, "baseApr": 0.034393413015504, "grossApy": 0.034990028836955345, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
53	2025-09-12 03:31:23.146+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
6	2025-09-09 22:32:49.517+00	750000	0.0906442157224512	0.08157979415020608	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.01332444030444806, "baseApr": 0.014696706322512, "grossApy": 0.014804933671608955, "rewardApr": 0, "dailyNetUsd": 10.76605750072311}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04062259124428287, "baseApr": 0.04414989374587338, "grossApy": 0.04513621249364763, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.01332444030444806, "baseApr": 0.014696706322512, "grossApy": 0.014804933671608955, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
7	2025-09-09 22:48:46.198+00	750000	0.09069347369976082	0.08162412632978473	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013437180754240875, "baseApr": 0.014820143345856, "grossApy": 0.014930200838045415, "rewardApr": 0, "dailyNetUsd": 10.857151020405254}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03926837220839676, "baseApr": 0.04270897996108595, "grossApy": 0.0436315246759964, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013437180754240875, "baseApr": 0.014820143345856, "grossApy": 0.014930200838045415, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
8	2025-09-09 23:21:06.752+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04071139603929248, "baseApr": 0.0442443113760192, "grossApy": 0.045234884488102756, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
9	2025-09-09 23:37:13.903+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03933761923930475, "baseApr": 0.04278271031315591, "grossApy": 0.043708465821449716, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
10	2025-09-09 23:53:25.627+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040715659206953574, "baseApr": 0.04424884377014926, "grossApy": 0.04523962134105952, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
54	2025-09-13 02:10:59.067+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
11	2025-09-10 00:10:13.617+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03934038879667419, "baseApr": 0.042785659069685525, "grossApy": 0.04371154310741576, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
12	2025-09-10 00:26:29.517+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040714102508285, "baseApr": 0.04424718876555652, "grossApy": 0.04523789167587222, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
13	2025-09-10 00:46:01.411+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.0407129616855761, "baseApr": 0.044245975897978664, "grossApy": 0.045236624095084554, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
14	2025-09-10 01:02:03.246+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03934827560105116, "baseApr": 0.042794056127834865, "grossApy": 0.04372030622339018, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
15	2025-09-10 01:18:11.713+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04073926983513015, "baseApr": 0.04427394507969537, "grossApy": 0.045265855372366826, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
55	2025-09-14 19:48:14.206+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
16	2025-09-10 01:34:28.65+00	750000	0.09062313936983017	0.08156082543284715	[{"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 10.72708068423216}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 91.2062281073098}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 65.65742839923988}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03936136985740757, "baseApr": 0.04280799738996574, "grossApy": 0.04373485539711952, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.1352186307927278, "baseApr": 0.14, "grossApy": 0.1502429231030309, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013276201265732524, "baseApr": 0.01464388582464, "grossApy": 0.014751334739702804, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.11472715407456012, "baseApr": 0.12, "grossApy": 0.12747461563840012, "rewardApr": 0, "dailyNetUsd": 0}]
17	2025-09-10 02:00:44.744+00	1499999.9999999998	0.044729453269703526	0.04025650794273318	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013226597775665084, "baseApr": 0.014589568386432, "grossApy": 0.014696219750738981, "rewardApr": 0, "dailyNetUsd": 10.687001400292232}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040803638324103296, "baseApr": 0.04434237434856665, "grossApy": 0.04533737591567033, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013226597775665084, "baseApr": 0.014589568386432, "grossApy": 0.014696219750738981, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
18	2025-09-10 02:11:58.912+00	1499999.9999999998	0.04475393328596321	0.04027853995736688	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 10.777543926184173}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.0394333532693649, "baseApr": 0.042884633608982696, "grossApy": 0.043814836965961, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
19	2025-09-10 02:11:58.979+00	1499999.9999999998	0.04475393328596321	0.04027853995736688	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 10.777543926184173}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.0394333532693649, "baseApr": 0.042884633608982696, "grossApy": 0.043814836965961, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
56	2025-09-14 19:48:14.259+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
20	2025-09-10 02:11:59.036+00	1499999.9999999998	0.04475393328596321	0.04027853995736688	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 10.777543926184173}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.0394333532693649, "baseApr": 0.042884633608982696, "grossApy": 0.043814836965961, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
21	2025-09-10 02:12:10.007+00	1499999.9999999998	0.04475393328596321	0.04027853995736688	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 10.777543926184173}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03944260654360874, "baseApr": 0.042894484564287925, "grossApy": 0.04382511838178749, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.01333865629673281, "baseApr": 0.014712271934976, "grossApy": 0.01482072921859201, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
22	2025-09-10 02:38:45.546+00	1499999.9999999998	0.04475249269059115	0.04027724342153204	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 10.772215696725924}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040862405810623816, "baseApr": 0.04440484519049104, "grossApy": 0.04540267312291535, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
23	2025-09-10 02:38:45.541+00	1499999.9999999998	0.04475249269059115	0.04027724342153204	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 10.772215696725924}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040862405810623816, "baseApr": 0.04440484519049104, "grossApy": 0.04540267312291535, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
57	2025-09-15 00:09:00.579+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
24	2025-09-10 02:38:45.546+00	1499999.9999999998	0.04475249269059115	0.04027724342153204	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 10.772215696725924}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040862405810623816, "baseApr": 0.04440484519049104, "grossApy": 0.04540267312291535, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
25	2025-09-10 02:38:45.591+00	1499999.9999999998	0.04475249269059115	0.04027724342153204	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 10.772215696725924}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040862405810623816, "baseApr": 0.04440484519049104, "grossApy": 0.04540267312291535, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013332061898055293, "baseApr": 0.014705051515488, "grossApy": 0.014813402108950324, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
26	2025-09-10 02:55:06.467+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03948490537089433, "baseApr": 0.04293951429594066, "grossApy": 0.04387211707877148, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
27	2025-09-10 02:55:06.754+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03948490537089433, "baseApr": 0.04293951429594066, "grossApy": 0.04387211707877148, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
58	2025-09-15 00:09:00.586+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
28	2025-09-10 02:55:06.852+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03948490537089433, "baseApr": 0.04293951429594066, "grossApy": 0.04387211707877148, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
29	2025-09-10 02:55:06.949+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03948490537089433, "baseApr": 0.04293951429594066, "grossApy": 0.04387211707877148, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
30	2025-09-10 03:11:25.3+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04107572640812356, "baseApr": 0.04463157593472003, "grossApy": 0.045639696009026176, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
31	2025-09-10 03:11:25.308+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04107572640812356, "baseApr": 0.04463157593472003, "grossApy": 0.045639696009026176, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
59	2025-09-15 00:24:05.446+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
32	2025-09-10 03:11:25.308+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04107572640812356, "baseApr": 0.04463157593472003, "grossApy": 0.045639696009026176, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
33	2025-09-10 03:26:39.8+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.039697531199843386, "baseApr": 0.0431658370897458, "grossApy": 0.04410836799982598, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
34	2025-09-10 03:26:39.835+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.039697531199843386, "baseApr": 0.0431658370897458, "grossApy": 0.04410836799982598, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
35	2025-09-10 03:26:39.836+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.039697531199843386, "baseApr": 0.0431658370897458, "grossApy": 0.04410836799982598, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
60	2025-09-15 00:24:05.446+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
36	2025-09-10 03:41:38.789+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03969777294363457, "baseApr": 0.04316609437716331, "grossApy": 0.04410863660403841, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
37	2025-09-10 03:41:38.801+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03969777294363457, "baseApr": 0.04316609437716331, "grossApy": 0.04410863660403841, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
38	2025-09-10 03:41:38.895+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03969777294363457, "baseApr": 0.04316609437716331, "grossApy": 0.04410863660403841, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
39	2025-09-10 03:56:39.058+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04109483714899396, "baseApr": 0.04465188554808798, "grossApy": 0.04566093016554884, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
61	2025-09-16 02:06:06.022+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
40	2025-09-10 03:56:39.088+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04109483714899396, "baseApr": 0.04465188554808798, "grossApy": 0.04566093016554884, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
41	2025-09-10 03:56:39.104+00	1499999.9999999998	0.04474176884932867	0.04026759196439581	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 10.73255217424826}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04109483714899396, "baseApr": 0.04465188554808798, "grossApy": 0.04566093016554884, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013282972968567197, "baseApr": 0.01465130083176, "grossApy": 0.014758858853963552, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
42	2025-09-10 04:11:39.273+00	1499999.9999999998	0.04474098602229126	0.04026688742006214	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013279389537938169, "baseApr": 0.014647376985984, "grossApy": 0.014754877264375743, "rewardApr": 0, "dailyNetUsd": 10.729656786575646}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03969695948223073, "baseApr": 0.0431652286116502, "grossApy": 0.044107732758034146, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013279389537938169, "baseApr": 0.014647376985984, "grossApy": 0.014754877264375743, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
43	2025-09-10 04:11:39.308+00	1499999.9999999998	0.04474098602229126	0.04026688742006214	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013279389537938169, "baseApr": 0.014647376985984, "grossApy": 0.014754877264375743, "rewardApr": 0, "dailyNetUsd": 10.729656786575646}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03969695948223073, "baseApr": 0.0431652286116502, "grossApy": 0.044107732758034146, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013279389537938169, "baseApr": 0.014647376985984, "grossApy": 0.014754877264375743, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
62	2025-09-16 02:06:06.316+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
44	2025-09-10 04:11:39.327+00	1499999.9999999998	0.04474098602229126	0.04026688742006214	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013279389537938169, "baseApr": 0.014647376985984, "grossApy": 0.014754877264375743, "rewardApr": 0, "dailyNetUsd": 10.729656786575646}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03969695948223073, "baseApr": 0.0431652286116502, "grossApy": 0.044107732758034146, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013279389537938169, "baseApr": 0.014647376985984, "grossApy": 0.014754877264375743, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
45	2025-09-10 04:36:57.947+00	1499999.9999999998	0.044739355830491934	0.04026542024744274	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013271927251959626, "baseApr": 0.014639205756096, "grossApy": 0.014746585835510695, "rewardApr": 0, "dailyNetUsd": 10.723627310057596}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04107741050690999, "baseApr": 0.044633365698494, "grossApy": 0.04564156722989998, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013271927251959626, "baseApr": 0.014639205756096, "grossApy": 0.014746585835510695, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
46	2025-09-10 04:51:58.107+00	1499999.9999999998	0.044732588479965515	0.04025932963196897	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013240949360299181, "baseApr": 0.014605284141792, "grossApy": 0.01471216595588798, "rewardApr": 0, "dailyNetUsd": 10.698597383453011}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.03968034990730989, "baseApr": 0.0431475509066747, "grossApy": 0.04408927767478876, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013240949360299181, "baseApr": 0.014605284141792, "grossApy": 0.01471216595588798, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
47	2025-09-10 17:27:59.328+00	1499999.9999999998	0.044745628277827854	0.04027106545004508	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013300639699062722, "baseApr": 0.014670645623856, "grossApy": 0.014778488554514135, "rewardApr": 0, "dailyNetUsd": 10.746826772806902}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040498687742808424, "baseApr": 0.04401814416875093, "grossApy": 0.044998541936453806, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013300639699062722, "baseApr": 0.014670645623856, "grossApy": 0.014778488554514135, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
63	2025-09-16 18:24:25.76+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
48	2025-09-10 17:27:59.351+00	1499999.9999999998	0.044745628277827854	0.04027106545004508	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013300639699062722, "baseApr": 0.014670645623856, "grossApy": 0.014778488554514135, "rewardApr": 0, "dailyNetUsd": 10.746826772806902}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.040498687742808424, "baseApr": 0.04401814416875093, "grossApy": 0.044998541936453806, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013300639699062722, "baseApr": 0.014670645623856, "grossApy": 0.014778488554514135, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
49	2025-09-12 02:08:10.267+00	1499999.9999999998	0.044759764708174464	0.040283788237357024	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013365349928868708, "baseApr": 0.014741499121344, "grossApy": 0.01485038880985412, "rewardApr": 0, "dailyNetUsd": 10.799112200116271}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04357075127082801, "baseApr": 0.04727964865086198, "grossApy": 0.04841194585647557, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013365349928868708, "baseApr": 0.014741499121344, "grossApy": 0.01485038880985412, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
50	2025-09-12 03:00:24.065+00	1499999.9999999998	0.04475978362873232	0.0402838052658591	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013365436538685826, "baseApr": 0.014741593950096, "grossApy": 0.014850485042984252, "rewardApr": 0, "dailyNetUsd": 10.799182180261774}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04359387674845305, "baseApr": 0.04730415999833309, "grossApy": 0.048437640831614504, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013365436538685826, "baseApr": 0.014741593950096, "grossApy": 0.014850485042984252, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
51	2025-09-12 03:00:24.117+00	1499999.9999999998	0.04475978362873232	0.0402838052658591	[{"key": "stride:cosmos:stJUNO", "usd": 309759.66694}, {"key": "justlend:tron:USDT", "usd": 294917.527339, "netApy": 0.013365436538685826, "baseApr": 0.014741593950096, "grossApy": 0.014850485042984252, "rewardApr": 0, "dailyNetUsd": 10.799182180261774}, {"key": "stride:cosmos:stTIA", "usd": 246195.905579, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 70.57634923110297}, {"key": "stride:cosmos:stLUNA", "usd": 236610.296591}, {"key": "stride:cosmos:stATOM", "usd": 208886.567082, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 84.17435324285071}, {"key": "stride:cosmos:stBAND", "usd": 203630.036469}, {"key": "aave:USDT", "usd": 0, "netApy": 0.04359387674845305, "baseApr": 0.04730415999833309, "grossApy": 0.048437640831614504, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stTIA", "usd": 0, "netApy": 0.10463361447368395, "baseApr": 0.11, "grossApy": 0.11625957163742662, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "justlend:USDT", "usd": 0, "netApy": 0.013365436538685826, "baseApr": 0.014741593950096, "grossApy": 0.014850485042984252, "rewardApr": 0, "dailyNetUsd": 0}, {"key": "stride:stJUNO", "usd": 0}, {"key": "stride:stLUNA", "usd": 0}, {"key": "stride:stATOM", "usd": 0, "netApy": 0.14708288504535436, "baseApr": 0.1514, "grossApy": 0.1634254278281715, "rewardApr": 0, "dailyNetUsd": 0}]
52	2025-09-12 03:31:07.487+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
64	2025-09-16 18:24:26.48+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
65	2025-09-16 18:40:18.084+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
66	2025-09-16 18:40:18.326+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
67	2025-09-16 18:56:19.526+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
68	2025-09-16 18:56:19.571+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
69	2025-09-16 19:12:22.014+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
70	2025-09-16 19:12:22.074+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
71	2025-09-16 19:28:25.779+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
72	2025-09-16 19:28:25.796+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
73	2025-09-16 19:44:29.671+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
74	2025-09-16 19:44:29.806+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
75	2025-09-16 20:00:34.764+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
76	2025-09-16 20:00:34.915+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
77	2025-09-16 20:16:39.843+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
78	2025-09-16 20:16:39.945+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
79	2025-09-16 20:32:45.921+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
80	2025-09-16 20:32:45.985+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
81	2025-09-16 20:48:51.718+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
82	2025-09-16 20:48:51.916+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
83	2025-09-16 21:04:59.113+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
84	2025-09-16 21:04:59.266+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
85	2025-09-16 21:36:09.926+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
86	2025-09-16 21:36:09.933+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
87	2025-09-16 21:36:10.154+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
88	2025-09-16 21:36:17.327+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
89	2025-09-16 22:54:01.892+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
90	2025-09-16 22:54:01.906+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
91	2025-09-16 22:54:01.912+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
92	2025-09-16 22:54:01.945+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
93	2025-09-16 22:54:01.955+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
94	2025-09-16 22:54:02.025+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
95	2025-09-16 22:54:02.077+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
96	2025-09-16 22:54:02.139+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
98	2025-09-16 23:10:58.132+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
97	2025-09-16 23:10:58.131+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
99	2025-09-16 23:10:58.146+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
100	2025-09-16 23:10:58.18+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
101	2025-09-16 23:10:58.25+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
102	2025-09-16 23:10:58.266+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
103	2025-09-16 23:10:58.308+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
104	2025-09-16 23:10:58.521+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
105	2025-09-16 23:26:00.657+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
106	2025-09-16 23:26:00.657+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
107	2025-09-16 23:26:00.675+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
108	2025-09-16 23:26:00.676+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
109	2025-09-16 23:26:00.683+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
110	2025-09-16 23:26:00.692+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
111	2025-09-16 23:26:00.694+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
112	2025-09-16 23:26:00.723+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
113	2025-09-16 23:41:00.543+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
114	2025-09-16 23:41:00.59+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
115	2025-09-16 23:41:00.597+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
116	2025-09-16 23:41:00.687+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
117	2025-09-16 23:41:00.782+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
118	2025-09-16 23:41:00.806+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
119	2025-09-16 23:41:00.807+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
120	2025-09-16 23:41:01.054+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
121	2025-09-16 23:56:00.391+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
122	2025-09-16 23:56:00.415+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
123	2025-09-16 23:56:00.432+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
124	2025-09-16 23:56:00.443+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
125	2025-09-16 23:56:00.445+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
126	2025-09-16 23:56:00.515+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
127	2025-09-16 23:56:00.524+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
128	2025-09-16 23:56:00.532+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
129	2025-09-17 00:11:00.421+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
130	2025-09-17 00:11:00.439+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
131	2025-09-17 00:11:00.46+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
132	2025-09-17 00:11:00.47+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
133	2025-09-17 00:11:00.477+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
134	2025-09-17 00:11:00.49+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
135	2025-09-17 00:11:00.505+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
136	2025-09-17 00:11:00.512+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
137	2025-09-17 00:54:48.757+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
138	2025-09-17 00:54:48.771+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
139	2025-09-17 01:06:24.241+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
140	2025-09-17 01:09:49.427+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
141	2025-09-17 01:09:49.537+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
142	2025-09-17 01:21:25.08+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
143	2025-09-17 01:24:50.253+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
144	2025-09-17 01:24:50.282+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
145	2025-09-17 01:36:26.532+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
146	2025-09-17 01:39:50.954+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
147	2025-09-17 01:39:51.025+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
148	2025-09-17 01:51:27.22+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
149	2025-09-17 01:54:52.12+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
150	2025-09-17 01:54:52.218+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
151	2025-09-17 16:56:46.965+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
152	2025-09-17 17:00:11.641+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
153	2025-09-17 17:00:11.769+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
154	2025-09-17 17:11:49.147+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
155	2025-09-17 17:15:14.657+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
156	2025-09-17 17:15:14.721+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
157	2025-09-17 17:34:51.957+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
158	2025-09-17 17:38:17.298+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
159	2025-09-17 17:38:17.613+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
160	2025-09-17 17:49:55.028+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
161	2025-09-17 17:53:20.387+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
162	2025-09-17 17:53:20.418+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
163	2025-09-17 19:29:52.677+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
164	2025-09-18 01:22:34.315+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
165	2025-09-18 01:37:34.418+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
166	2025-09-18 01:52:34.614+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
167	2025-09-18 02:07:34.897+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
168	2025-09-18 02:29:18.889+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
169	2025-09-18 02:44:19.982+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
170	2025-09-18 03:14:21.149+00	1350000	0.21123132736899852	0.19010819463209866	[{"key": "stride:cosmos:stJUNO", "usd": 557567.55, "netApy": 0.2283647066005803, "baseApr": 0.2262, "grossApy": 0.25373856288953367, "rewardApr": 0, "dailyNetUsd": 348.84589031713534}, {"key": "stride:cosmos:stLUNA", "usd": 425898, "netApy": 0.17443665759783628, "baseApr": 0.1772, "grossApy": 0.1938185084420403, "rewardApr": 0, "dailyNetUsd": 203.5403386235706}, {"key": "stride:cosmos:stBAND", "usd": 366534.45, "netApy": 0.1501225578931953, "baseApr": 0.1543, "grossApy": 0.16680284210355034, "rewardApr": 0, "dailyNetUsd": 150.75366901363154}]
\.


--
-- Data for Name: allocation_targets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocation_targets (id, key, weight_fraction, source, applied_at, expires_at) FROM stdin;
1	stride:cosmos:stJUNO	0.413013	override	2025-09-10 02:00:42.95299+00	\N
2	stride:cosmos:stLUNA	0.315480	override	2025-09-10 02:00:42.95299+00	\N
3	stride:cosmos:stBAND	0.271507	override	2025-09-10 02:00:42.95299+00	\N
\.


--
-- Data for Name: allocations_current; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocations_current (chain, weight_fraction, updated_from_proposal, updated_at) FROM stdin;
sui	0.10000	\N	2025-09-02 23:12:31.088663+00
aptos	0.40000	\N	2025-09-02 23:12:31.088663+00
cosmos	0.50000	\N	2025-09-02 23:12:31.088663+00
\.


--
-- Data for Name: allocations_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.allocations_history (id, chain, weight_fraction, proposal_id, effective_at, executed_at) FROM stdin;
1	sui	0.45000	1	2025-08-25 23:26:05.631587+00	2025-08-25 23:26:05.631587+00
2	aptos	0.30000	1	2025-08-25 23:26:05.631587+00	2025-08-25 23:26:05.631587+00
3	cosmos	0.25000	1	2025-08-25 23:26:05.631587+00	2025-08-25 23:26:05.631587+00
4	sui	0.20000	2	2025-08-26 00:49:59.137284+00	2025-08-26 00:49:59.137284+00
5	aptos	0.40000	2	2025-08-26 00:49:59.137284+00	2025-08-26 00:49:59.137284+00
6	cosmos	0.40000	2	2025-08-26 00:49:59.137284+00	2025-08-26 00:49:59.137284+00
7	sui	0.20000	3	2025-08-31 07:30:51.689015+00	2025-08-31 07:30:51.689015+00
8	aptos	0.40000	3	2025-08-31 07:30:51.689015+00	2025-08-31 07:30:51.689015+00
9	cosmos	0.40000	3	2025-08-31 07:30:51.689015+00	2025-08-31 07:30:51.689015+00
10	sui	0.10000	8	2025-09-02 23:12:31.088663+00	2025-09-02 23:12:31.088663+00
11	aptos	0.40000	8	2025-09-02 23:12:31.088663+00	2025-09-02 23:12:31.088663+00
12	cosmos	0.50000	8	2025-09-02 23:12:31.088663+00	2025-09-02 23:12:31.088663+00
\.


--
-- Data for Name: apy_tiers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.apy_tiers (min_weeks, apy_bps) FROM stdin;
0	500
3	800
12	1200
26	1600
52	2000
104	2400
\.


--
-- Data for Name: balances; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.balances (user_id, hyapi_amount, updated_at) FROM stdin;
1	1119464.600695000000000000	2025-08-25 02:06:13.811056+00
\.


--
-- Data for Name: delegations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.delegations (id, chain, provider, action, amount, tx_ref, created_at) FROM stdin;
\.


--
-- Data for Name: exchanges; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exchanges (id, user_id, src_asset, dst_asset, amount_src, amount_dst, rate, provider, tx_ref, created_at) FROM stdin;
\.


--
-- Data for Name: gov_allocation_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_allocation_history (id, proposal_id, key, weight_fraction, applied_at, normalization) FROM stdin;
\.


--
-- Data for Name: gov_execution_queue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_execution_queue (id, proposal_id, queued_at, execute_not_before, executed_at) FROM stdin;
\.


--
-- Data for Name: gov_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_params (id, quorum_bps, pass_threshold_bps, min_proposer_power_bps, proposal_fee_pi, vote_duration_days, epoch_cadence, max_chain_weight_bps, min_pi_buffer_bps) FROM stdin;
1	2000	5000	100	0.000000000000000000	7	quarterly	4000	1000
\.


--
-- Data for Name: gov_power_snapshot_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_power_snapshot_items (snapshot_id, user_id, voting_power) FROM stdin;
1	1	1000.000000000000000000
2	1	1000.000000000000000000
3	1	101000.000000000000000000
4	1	1312566.844920000000000000
5	1	1268091.995320000000000000
6	1	1268091.995320000000000000
7	1	1268091.995320000000000000
8	1	10.000000000000000000
9	1	40.312500000000000000
10	1	1119464.600695000000000000
\.


--
-- Data for Name: gov_power_snapshots; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_power_snapshots (id, snap_ts, total_hyapi_supply, notes) FROM stdin;
1	2025-08-25 02:40:55.580889+00	1000.000000000000000000	\N
2	2025-08-26 00:47:38.067549+00	1000.000000000000000000	\N
3	2025-08-31 03:13:13.548343+00	101000.000000000000000000	\N
4	2025-08-31 20:25:25.30869+00	1312566.844920000000000000	\N
5	2025-08-31 23:31:59.682642+00	1268091.995320000000000000	\N
6	2025-08-31 23:33:07.465389+00	1268091.995320000000000000	\N
7	2025-09-01 00:42:08.632184+00	1268091.995320000000000000	\N
8	2025-09-02 23:12:08.298584+00	10.000000000000000000	\N
9	2025-09-03 02:01:33.603826+00	40.312500000000000000	\N
10	2025-09-10 02:07:15.846809+00	1119464.600695000000000000	\N
\.


--
-- Data for Name: gov_proposal_allocations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_proposal_allocations (proposal_id, key, weight_fraction) FROM stdin;
1	sui	0.45000
1	aptos	0.30000
1	cosmos	0.25000
2	sui	0.20000
2	aptos	0.40000
2	cosmos	0.40000
3	sui	0.20000
3	aptos	0.40000
3	cosmos	0.40000
4	sui	0.10000
4	aptos	0.40000
4	cosmos	0.50000
5	sui	0.30000
5	aptos	0.40000
5	cosmos	0.30000
6	sui	0.30000
6	aptos	0.40000
6	cosmos	0.30000
7	sui	0.20000
7	aptos	0.45000
7	cosmos	0.35000
8	sui	0.10000
8	aptos	0.40000
8	cosmos	0.50000
9	sui	0.20000
9	aptos	0.40000
9	cosmos	0.40000
10	aave:USDT	0.33333
10	justlend:USDT	0.33333
10	stride:stATOM	0.33333
\.


--
-- Data for Name: gov_proposals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_proposals (id, title, description, proposer_user_id, snapshot_id, start_ts, end_ts, status, created_at, quorum_met, passed, total_votes_power, updated_at, executed_at) FROM stdin;
1	Q4 Allocation: 45% Sui / 30% Aptos / 25% Cosmos	Raise Sui exposure modestly; keep Cosmos steady.	1	1	2025-08-25 02:40:55.588+00	2025-09-01 02:40:55.588+00	executed	2025-08-25 02:40:55.588695+00	t	t	1000000000000000000000	2025-08-25 23:26:05.631587+00	2025-08-25 23:26:05.631587+00
2	Q4 test test test	test test test	1	2	2025-08-26 00:47:38.144+00	2025-09-02 00:47:38.144+00	executed	2025-08-26 00:47:38.144367+00	t	t	1000000000000000000000	2025-08-26 00:49:59.137284+00	2025-08-26 00:49:59.137284+00
3	Q4 Allocation adjustment	Aptos and Cosmos are looking to be ready to a bounce and Id like to adjust allocation to a lest risk momentum	1	3	2025-08-31 03:13:13.562+00	2025-09-07 03:13:13.562+00	executed	2025-08-31 03:13:13.562971+00	t	t	210625668449000002420736	2025-08-31 07:30:51.689015+00	2025-08-31 07:30:51.689015+00
4	Q1 2026 Proposal Change provider from SUI to SOL staking reducing risk but robust holdings base	We expect the high yield meme sector to continue to explode in the coming year and want to derisk from sui	1	4	2025-08-31 20:25:25.345+00	2025-09-07 20:25:25.345+00	finalized	2025-08-31 20:25:25.345198+00	t	f	1312566844920000088637440	2025-08-31 20:50:03.25934+00	\N
5	test test test	test test test	1	5	2025-08-31 23:31:59.688+00	2025-09-07 23:31:59.688+00	finalized	2025-08-31 23:31:59.688936+00	t	f	1268091995320000018644992	2025-08-31 23:32:30.459869+00	\N
6	test test test	test test test	1	6	2025-08-31 23:33:07.476+00	2025-09-07 23:33:07.476+00	finalized	2025-08-31 23:33:07.476637+00	t	f	1268091995320000018644992	2025-09-01 00:34:25.576428+00	\N
7	Q4 allocation SUI deleverage risk to Aptos and Cosmos	SUI has been very volatile and we need to deleverage and stretch ivnvested funds across aptos and comsos	1	7	2025-09-01 00:42:08.649+00	2025-09-08 00:42:08.649+00	finalized	2025-09-01 00:42:08.650241+00	t	f	1268091995320000018644992	2025-09-01 00:45:32.181952+00	\N
8	Q4 allocations updated.	We see a lot of upside in Aptos and Cosmos network despite the long unbonding periods, we like there isnt slashing penalties on both platforms and are motivated to risk on heavier into those two chains especially since Sui is getting between 2-7% through various staking providers.	1	8	2025-09-02 23:12:08.309+00	2025-09-09 23:12:08.309+00	executed	2025-09-02 23:12:08.309547+00	t	t	10000000000000000000	2025-09-02 23:12:31.088663+00	2025-09-02 23:12:31.088663+00
9	test test test	test test test	1	9	2025-09-03 02:01:33.614+00	2025-09-10 02:01:33.614+00	finalized	2025-09-03 02:01:33.614856+00	t	f	40312500000000000000	2025-09-03 02:01:50.422815+00	\N
10	Q4b Allocation adjustment	Test test test	1	10	2025-09-10 02:07:15.861+00	2025-09-17 02:07:15.861+00	active	2025-09-10 02:07:15.862049+00	f	f	0	2025-09-10 02:07:15.862049+00	\N
\.


--
-- Data for Name: gov_tallies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_tallies (proposal_id, for_power, against_power, abstain_power) FROM stdin;
1	1000000000000000000000	0	0
2	1000000000000000000000	0	0
3	210625668449000002420736	0	0
4	0	0	1312566844920000088637440
5	0	1268091995320000018644992	0
6	0	1268091995320000018644992	0
7	0	0	1268091995320000018644992
8	10000000000000000000	0	0
9	0	0	40312500000000000000
10	0	0	0
\.


--
-- Data for Name: gov_votes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gov_votes (proposal_id, user_id, support, voting_power, cast_at, power, created_at, updated_at) FROM stdin;
1	1	1	1000000000000000000000	2025-08-25 22:23:32.156378+00	\N	2025-08-25 23:09:53.32744+00	2025-08-25 23:10:06.00414+00
2	1	1	1000000000000000000000	2025-08-26 00:49:39.60543+00	\N	2025-08-26 00:49:39.60543+00	2025-08-26 00:49:39.60543+00
3	1	1	210625668449000002420736	2025-08-31 07:30:42.117107+00	\N	2025-08-31 07:30:42.117107+00	2025-08-31 07:30:42.117107+00
4	1	2	1312566844920000088637440	2025-08-31 20:25:53.345865+00	\N	2025-08-31 20:25:53.345865+00	2025-08-31 20:25:53.345865+00
5	1	0	1268091995320000018644992	2025-08-31 23:32:17.898586+00	\N	2025-08-31 23:32:17.898586+00	2025-08-31 23:32:17.898586+00
6	1	0	1268091995320000018644992	2025-09-01 00:34:23.23377+00	\N	2025-09-01 00:34:23.23377+00	2025-09-01 00:34:23.23377+00
7	1	2	1268091995320000018644992	2025-09-01 00:43:10.816051+00	\N	2025-09-01 00:43:10.816051+00	2025-09-01 00:43:10.816051+00
8	1	1	10000000000000000000	2025-09-02 23:12:16.588419+00	\N	2025-09-02 23:12:16.588419+00	2025-09-02 23:12:16.588419+00
9	1	2	40312500000000000000	2025-09-03 02:01:47.758788+00	\N	2025-09-03 02:01:47.758788+00	2025-09-03 02:01:47.758788+00
\.


--
-- Data for Name: liquidity_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.liquidity_events (id, kind, amount_usd, venue_key, tx_ref, idem_key, plan_version, created_at) FROM stdin;
1	rebalance_out	30975.966694	stride:cosmos:stJUNO	plan:buffer-topup	\N	\N	2025-09-12 02:17:27.054828+00
2	rebalance_out	29491.752734	justlend:tron:USDT	plan:buffer-topup	\N	\N	2025-09-12 02:17:27.067473+00
3	rebalance_out	24619.590558	stride:cosmos:stTIA	plan:buffer-topup	\N	\N	2025-09-12 02:17:27.077013+00
4	rebalance_out	30975.966694	stride:cosmos:stJUNO	plan:buffer-topup	\N	\N	2025-09-12 02:21:13.253243+00
5	rebalance_out	29491.752734	justlend:tron:USDT	plan:buffer-topup	\N	\N	2025-09-12 02:21:13.262943+00
6	rebalance_out	24619.590558	stride:cosmos:stTIA	plan:buffer-topup	\N	\N	2025-09-12 02:21:13.272685+00
7	rebalance_out	30975.966694	stride:cosmos:stJUNO	plan:buffer-topup	\N	\N	2025-09-12 02:34:09.334192+00
8	rebalance_out	29491.752734	justlend:tron:USDT	plan:buffer-topup	\N	\N	2025-09-12 02:34:09.344413+00
9	rebalance_out	24619.590558	stride:cosmos:stTIA	plan:buffer-topup	\N	\N	2025-09-12 02:34:09.353267+00
\.


--
-- Data for Name: pi_identities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pi_identities (uid, user_id, username, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: pi_payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pi_payments (id, pi_payment_id, direction, uid, amount_pi, status, txid, created_at, updated_at) FROM stdin;
1	dev-a2u-1756861237856	A2U	unknown	1.875000	completed	dev-txid-1757021951894	2025-09-03 01:00:37.642163+00	2025-09-04 21:39:11.895011+00
2	dev-a2u-1756863514174	A2U	unknown	40.312500	completed	dev-txid-1757021951902	2025-09-03 01:38:34.094933+00	2025-09-04 21:39:11.903177+00
\.


--
-- Data for Name: planned_actions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.planned_actions (id, kind, venue_key, amount_usd, status, reason, created_at, updated_at, idem_key) FROM stdin;
1	redeem	stride:cosmos:stJUNO	30975.966694	pending	top_up_buffer	2025-09-12 02:17:27.048874+00	2025-09-12 02:17:27.048874+00	redeem:stride:cosmos:stJUNO:1757643447029
2	redeem	justlend:tron:USDT	29491.752734	pending	top_up_buffer	2025-09-12 02:17:27.064742+00	2025-09-12 02:17:27.064742+00	redeem:justlend:tron:USDT:1757643447058
3	redeem	stride:cosmos:stTIA	24619.590558	pending	top_up_buffer	2025-09-12 02:17:27.074639+00	2025-09-12 02:17:27.074639+00	redeem:stride:cosmos:stTIA:1757643447069
4	redeem	stride:cosmos:stJUNO	30975.966694	pending	top_up_buffer	2025-09-12 02:21:13.250286+00	2025-09-12 02:21:13.250286+00	redeem:stride:cosmos:stJUNO:1757643673244
5	redeem	justlend:tron:USDT	29491.752734	pending	top_up_buffer	2025-09-12 02:21:13.259861+00	2025-09-12 02:21:13.259861+00	redeem:justlend:tron:USDT:1757643673254
6	redeem	stride:cosmos:stTIA	24619.590558	pending	top_up_buffer	2025-09-12 02:21:13.270161+00	2025-09-12 02:21:13.270161+00	redeem:stride:cosmos:stTIA:1757643673264
7	redeem	stride:cosmos:stJUNO	30975.966694	pending	top_up_buffer	2025-09-12 02:34:09.32703+00	2025-09-12 02:34:09.32703+00	redeem:stride:cosmos:stJUNO:1757644449316
8	redeem	justlend:tron:USDT	29491.752734	pending	top_up_buffer	2025-09-12 02:34:09.341916+00	2025-09-12 02:34:09.341916+00	redeem:justlend:tron:USDT:1757644449336
9	redeem	stride:cosmos:stTIA	24619.590558	pending	top_up_buffer	2025-09-12 02:34:09.35095+00	2025-09-12 02:34:09.35095+00	redeem:stride:cosmos:stTIA:1757644449345
\.


--
-- Data for Name: pps_series; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pps_series (id, as_of_date, pps_1e18, fees_1e18, created_at) FROM stdin;
1	2025-08-26	1000000000000000000	0	2025-08-26 02:24:05.028255+00
2	2025-08-27	1000500000000000000	0	2025-08-27 00:00:49.313323+00
3	2025-08-28	1001000250000000000	0	2025-08-28 02:22:02.082045+00
4	2025-08-29	1001500750125000000	0	2025-08-29 17:01:27.283508+00
5	2025-08-30	1002001500500062500	0	2025-08-30 16:22:36.603185+00
6	2025-08-31	1002502501250312531	0	2025-08-31 02:52:09.670244+00
7	2025-09-01	1003003752500937687	0	2025-09-01 00:28:50.29673+00
8	2025-09-02	1003505254377188155	0	2025-09-02 19:17:31.143113+00
9	2025-09-03	1004007007004376749	0	2025-09-03 00:00:00.687341+00
10	2025-09-04	1004509010507878937	0	2025-09-04 20:16:21.502138+00
11	2025-09-05	1005011265013132876	0	2025-09-05 00:00:47.880688+00
12	2025-09-06	1005513770645639442	0	2025-09-06 03:24:48.960184+00
13	2025-09-07	1006016527530962261	0	2025-09-07 03:02:46.912306+00
14	2025-09-08	1006519535794727742	0	2025-09-08 00:00:19.754125+00
15	2025-09-09	1007022795562625105	0	2025-09-09 22:11:02.436364+00
16	2025-09-10	1007526306960406417	0	2025-09-10 00:00:27.91875+00
17	2025-09-11	1008030070113886620	0	2025-09-11 00:29:09.602409+00
18	2025-09-12	1008534085148943563	0	2025-09-12 01:54:06.321033+00
19	2025-09-13	1009038352191518034	0	2025-09-13 02:06:56.678552+00
21	2025-09-14	1009542871367613793	0	2025-09-14 19:41:09.784042+00
23	2025-09-15	1010047642803297599	0	2025-09-15 00:08:58.740832+00
24	2025-09-16	1010552666624699247	0	2025-09-16 02:02:57.504091+00
25	2025-09-17	1011057942958011596	0	2025-09-17 00:00:58.571324+00
26	2025-09-18	1011563471929490601	0	2025-09-18 00:57:18.52053+00
\.


--
-- Data for Name: proposal_status_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proposal_status_history (id, proposal_id, from_status, to_status, changed_at) FROM stdin;
\.


--
-- Data for Name: rebalance_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rebalance_plans (id, tvl_usd, actions_json, created_at, buffer_usd, drift_bps, target_json, status) FROM stdin;
1	4000.000000	[{"key": "aave:USDT", "usd": 2640, "action": "withdraw"}, {"key": "justlend:USDT", "usd": 1000, "action": "deposit"}, {"key": "stride:stATOM", "usd": 1000, "action": "deposit"}]	2025-09-05 02:03:32.84782+00	0.000000	0	{}	planned
2	10000.000000	[{"key": "aave:USDT", "kind": "increase", "deltaUSD": 663.1578947368421}, {"key": "justlend:USDT", "kind": "increase", "deltaUSD": 2652.6315789473683}, {"key": "stride:stATOM", "kind": "increase", "deltaUSD": 4283.010358581139}, {"key": "stride:stTIA", "kind": "increase", "deltaUSD": 1401.200167734651}, {"kind": "buffer", "deltaUSD": 1000}]	2025-09-06 04:08:09.079238+00	1000.000000	10000	{"aave:USDT": 0.07368421052631578, "stride:stTIA": 0.1556889075260723, "justlend:USDT": 0.29473684210526313, "stride:stATOM": 0.4758900398423488}	executed
3	513598.082003	[{"key": "justlend:tron:USDT", "kind": "decrease", "deltaUSD": 256799.04100128118}, {"key": "stride:cosmos:stTIA", "kind": "increase", "deltaUSD": 138926.1864588594}, {"key": "stride:cosmos:stATOM", "kind": "increase", "deltaUSD": 117872.8545424217}]	2025-09-07 18:56:47.705825+00	0.000000	0	{"justlend:tron:USDT": 0.3891213778063609, "stride:cosmos:stTIA": 0.3304803516387791, "stride:cosmos:stATOM": 0.28039827055486}	executed
4	1600000.000000	[{"key": "aave:USDT", "kind": "decrease", "deltaUSD": 500000}, {"key": "justlend:USDT", "kind": "decrease", "deltaUSD": 150000}, {"key": "stride:stATOM", "kind": "decrease", "deltaUSD": 150000}, {"key": "justlend:tron:USDT", "kind": "increase", "deltaUSD": 309262.14735358435}, {"key": "stride:cosmos:stTIA", "kind": "increase", "deltaUSD": 265485.17530809663}, {"key": "stride:cosmos:stATOM", "kind": "increase", "deltaUSD": 225252.67733831904}]	2025-09-07 19:47:31.133069+00	0.000000	0	{"justlend:tron:USDT": 0.3865776841919804, "stride:cosmos:stTIA": 0.3318564691351208, "stride:cosmos:stATOM": 0.2815658466728988}	executed
5	1480000.000000	[{"key": "aave:USDT", "kind": "decrease", "deltaUSD": 500000}, {"key": "justlend:USDT", "kind": "decrease", "deltaUSD": 130000}, {"key": "stride:stATOM", "kind": "decrease", "deltaUSD": 110000}, {"key": "justlend:tron:USDT", "kind": "increase", "deltaUSD": 281242.47384836664}, {"key": "stride:cosmos:stTIA", "kind": "increase", "deltaUSD": 248184.07953956857}, {"key": "stride:cosmos:stATOM", "kind": "increase", "deltaUSD": 210573.44661206478}]	2025-09-07 19:54:36.052333+00	0.000000	0	{"justlend:tron:USDT": 0.38005739709238734, "stride:cosmos:stTIA": 0.33538389126968726, "stride:cosmos:stATOM": 0.2845587116379254}	executed
6	476400.000000	[{"key": "stride:stTIA", "kind": "decrease", "deltaUSD": 238199.99999999997}, {"key": "justlend:USDT", "kind": "increase", "deltaUSD": 124100}, {"key": "stride:stATOM", "kind": "increase", "deltaUSD": 114100}]	2025-09-07 20:20:27.984187+00	0.000000	0	{"stride:stTIA": 0.34, "justlend:USDT": 0.33, "stride:stATOM": 0.33}	executed
7	1540000.000000	[{"key": "stride:stTIA", "kind": "decrease", "deltaUSD": 500000}, {"key": "justlend:USDT", "kind": "decrease", "deltaUSD": 130000}, {"key": "stride:stATOM", "kind": "decrease", "deltaUSD": 140000}, {"key": "stride:cosmos:stTIA", "kind": "increase", "deltaUSD": 282194.31489934976}, {"key": "justlend:tron:USDT", "kind": "increase", "deltaUSD": 248376.0262243542}, {"key": "stride:cosmos:stATOM", "kind": "increase", "deltaUSD": 239429.65887629602}]	2025-09-07 20:22:57.114715+00	0.000000	0	{"justlend:tron:USDT": 0.3225662678238366, "stride:cosmos:stTIA": 0.3664861232459088, "stride:cosmos:stATOM": 0.3109476089302546}	executed
8	1500000.000000	[{"key": "stride:stTIA", "kind": "decrease", "deltaUSD": 500000}, {"key": "justlend:USDT", "kind": "decrease", "deltaUSD": 140000}, {"key": "stride:stATOM", "kind": "decrease", "deltaUSD": 110000}, {"key": "justlend:tron:USDT", "kind": "increase", "deltaUSD": 294917.52733864146}, {"key": "stride:cosmos:stTIA", "kind": "increase", "deltaUSD": 246195.90557892804}, {"key": "stride:cosmos:stATOM", "kind": "increase", "deltaUSD": 208886.5670824305}]	2025-09-07 23:21:53.47126+00	0.000000	0	{"justlend:tron:USDT": 0.3932233697848553, "stride:cosmos:stTIA": 0.32826120743857073, "stride:cosmos:stATOM": 0.278515422776574}	executed
9	1500000.000000	[{"key": "stride:stJUNO", "kind": "decrease", "deltaUSD": 500000}, {"key": "stride:stLUNA", "kind": "decrease", "deltaUSD": 130000}, {"key": "stride:stATOM", "kind": "decrease", "deltaUSD": 120000}, {"key": "stride:cosmos:stJUNO", "kind": "increase", "deltaUSD": 309759.6669403238}, {"key": "stride:cosmos:stLUNA", "kind": "increase", "deltaUSD": 236610.29659103966}, {"key": "stride:cosmos:stBAND", "kind": "increase", "deltaUSD": 203630.03646863654}]	2025-09-10 02:00:42.935776+00	0.000000	0	{"stride:cosmos:stBAND": 0.2715067152915154, "stride:cosmos:stJUNO": 0.41301288925376506, "stride:cosmos:stLUNA": 0.31548039545471956}	executed
\.


--
-- Data for Name: redemptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.redemptions (id, user_id, stake_id, amount_pi, eta_ts, needs_unstake, status, created_at, updated_at) FROM stdin;
1	1	\N	20.000000	\N	f	paid	2025-08-27 00:21:01.06507+00	2025-08-27 00:21:01.06507+00
2	1	\N	100.000000	\N	f	paid	2025-08-30 17:18:13.878954+00	2025-08-30 17:18:13.878954+00
3	1	\N	1000.000000	2025-09-20 17:18:19.165+00	t	pending	2025-08-30 17:18:19.163598+00	2025-08-30 17:18:19.163598+00
4	1	\N	80.000000	\N	f	paid	2025-08-30 17:18:41.826157+00	2025-08-30 17:18:41.826157+00
5	1	\N	210625.668449	2025-09-21 07:54:58.708+00	t	pending	2025-08-31 07:54:58.704723+00	2025-08-31 07:54:58.704723+00
6	1	\N	250000.000000	2025-09-21 20:23:38.378+00	t	pending	2025-08-31 20:23:38.37526+00	2025-08-31 20:23:38.37526+00
7	1	\N	656283.422460	2025-09-21 21:13:18.895+00	t	pending	2025-08-31 21:13:18.892306+00	2025-08-31 21:13:18.892306+00
8	1	\N	1242212.566845	2025-09-21 22:40:11.008+00	t	pending	2025-08-31 22:40:11.004812+00	2025-08-31 22:40:11.004812+00
9	1	\N	1268091.995320	2025-09-22 00:51:24.077+00	t	pending	2025-09-01 00:51:24.070629+00	2025-09-01 00:51:24.070629+00
10	1	\N	5.000000	\N	f	paid	2025-09-02 23:13:38.500819+00	2025-09-02 23:13:38.500819+00
11	1	\N	7.500000	\N	f	paid	2025-09-03 00:42:22.877208+00	2025-09-03 00:42:22.877208+00
12	1	\N	1.875000	\N	f	paid	2025-09-03 01:00:37.642163+00	2025-09-03 01:00:37.642163+00
13	1	\N	40.312500	\N	f	paid	2025-09-03 01:38:34.094933+00	2025-09-03 01:38:34.094933+00
14	1	\N	1119464.600694	2025-10-01 02:03:11.612+00	t	pending	2025-09-10 02:03:11.606806+00	2025-09-10 02:03:11.606806+00
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, applied_at) FROM stdin;
\.


--
-- Data for Name: stakes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stakes (id, user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps, early_exit_fee_bps, created_at, start_ts, status, updated_at, unlock_ts) FROM stdin;
1	1	100.000000	0	500	50	0	2025-08-27 00:20:29.006995+00	2025-08-27 00:20:29.006995+00	active	2025-08-27 00:20:29.006995+00	2025-08-27 00:20:29.006995+00
2	1	100.000000	25	1200	0	0	2025-08-27 02:48:27.198858+00	2025-08-27 02:48:27.198858+00	active	2025-08-27 02:48:27.198858+00	2026-02-18 02:48:27.198858+00
3	1	100.000000	54	2000	0	0	2025-08-30 17:46:53.350329+00	2025-08-30 17:46:53.350329+00	active	2025-08-30 17:46:53.350329+00	2026-09-12 17:46:53.350329+00
4	1	900.000000	54	2000	0	0	2025-08-30 17:46:59.643333+00	2025-08-30 17:46:59.643333+00	active	2025-08-30 17:46:59.643333+00	2026-09-12 17:46:59.643333+00
5	1	100000.000000	54	2000	0	0	2025-08-30 17:47:05.312622+00	2025-08-30 17:47:05.312622+00	active	2025-08-30 17:47:05.312622+00	2026-09-12 17:47:05.312622+00
6	1	109625.668449	52	2000	0	0	2025-08-31 06:54:10.87732+00	2025-08-31 06:54:10.87732+00	active	2025-08-31 06:54:10.87732+00	2026-08-30 06:54:10.87732+00
7	1	1000000.000000	104	2400	0	0	2025-08-31 08:09:26.093258+00	2025-08-31 08:09:26.093258+00	active	2025-08-31 08:09:26.093258+00	2027-08-29 08:09:26.093258+00
8	1	562566.844920	104	2400	0	0	2025-08-31 20:24:03.682545+00	2025-08-31 20:24:03.682545+00	active	2025-08-31 20:24:03.682545+00	2027-08-29 20:24:03.682545+00
9	1	1000000.000000	52	2000	0	0	2025-08-31 21:19:00.479776+00	2025-08-31 21:19:00.479776+00	active	2025-08-31 21:19:00.479776+00	2026-08-30 21:19:00.479776+00
10	1	310553.141711	0	500	50	0	2025-08-31 23:27:27.277471+00	2025-08-31 23:27:27.277471+00	active	2025-08-31 23:27:27.277471+00	2025-08-31 23:27:27.277471+00
11	1	543467.997994	104	2400	0	0	2025-08-31 23:28:04.777232+00	2025-08-31 23:28:04.777232+00	active	2025-08-31 23:28:04.777232+00	2027-08-29 23:28:04.777232+00
12	1	10.000000	0	500	50	0	2025-09-02 23:02:45.320592+00	2025-09-02 23:02:45.320592+00	active	2025-09-02 23:02:45.320592+00	2025-09-02 23:02:45.320592+00
13	1	10.000000	0	500	50	0	2025-09-03 00:40:34.968069+00	2025-09-03 00:40:34.968069+00	active	2025-09-03 00:40:34.968069+00	2025-09-03 00:40:34.968069+00
14	1	25.000000	26	1600	0	0	2025-09-03 01:37:50.725448+00	2025-09-03 01:37:50.725448+00	active	2025-09-03 01:37:50.725448+00	2026-03-04 01:37:50.725448+00
15	1	50.000000	104	2400	0	0	2025-09-03 01:38:23.006541+00	2025-09-03 01:38:23.006541+00	active	2025-09-03 01:38:23.006541+00	2027-09-01 01:38:23.006541+00
16	1	750000.000000	52	2000	0	0	2025-09-05 02:04:25.790451+00	2025-09-05 02:04:25.790451+00	active	2025-09-05 02:04:25.790451+00	2026-09-04 02:04:25.790451+00
17	1	1000000.000000	52	2000	0	0	2025-09-05 02:48:09.892915+00	2025-09-05 02:48:09.892915+00	active	2025-09-05 02:48:09.892915+00	2026-09-04 02:48:09.892915+00
18	1	488888.888889	26	1600	0	0	2025-09-05 03:13:47.472503+00	2025-09-05 03:13:47.472503+00	active	2025-09-05 03:13:47.472503+00	2026-03-06 03:13:47.472503+00
\.


--
-- Data for Name: treasury; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.treasury (id, buffer_pi, last_updated) FROM stdin;
t	245.312500	2025-09-03 01:38:34.094933+00
\.


--
-- Data for Name: tvl_buffer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tvl_buffer (id, buffer_usd, updated_at) FROM stdin;
1	150000.000000	2025-09-13 02:10:57.246968+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, pi_address, created_at, kyc_status) FROM stdin;
1	pi_dev_address	2025-08-25 02:06:13.808777+00	unknown
\.


--
-- Data for Name: venue_holdings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venue_holdings (key, usd_notional, updated_at) FROM stdin;
stride:cosmos:stJUNO	557567.550000	2025-09-13 02:10:57.23524+00
stride:cosmos:stLUNA	425898.000000	2025-09-13 02:10:57.23524+00
stride:cosmos:stBAND	366534.450000	2025-09-13 02:10:57.23524+00
\.


--
-- Data for Name: venue_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venue_rates (id, key, base_apr, as_of, created_at, venue, chain, market, base_apy, reward_apr, reward_apy, source, fetched_at) FROM stdin;
659	aave:USDT	0.04242915	2025-09-07 23:28:25.735+00	2025-09-07 23:28:27.972154+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:27.972154+00
660	aave:USDC	0.02405281	2025-09-07 23:28:25.735+00	2025-09-07 23:28:27.977401+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:27.977401+00
661	aave:DAI	0.03575518	2025-09-07 23:28:25.735+00	2025-09-07 23:28:27.982024+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:27.982024+00
662	aave:USDT	0.03724569	2025-09-07 23:28:25.735+00	2025-09-07 23:28:27.985672+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:27.985672+00
663	aave:USDC	0.05528768	2025-09-07 23:28:25.735+00	2025-09-07 23:28:28.057942+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.057942+00
664	aave:USDC	0.04899767	2025-09-07 23:28:25.735+00	2025-09-07 23:28:28.067249+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.067249+00
665	aave:USDT	0.02844440	2025-09-07 23:28:25.735+00	2025-09-07 23:28:28.070842+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.070842+00
666	aave:DAI	0.03463319	2025-09-07 23:28:25.735+00	2025-09-07 23:28:28.074104+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.074104+00
667	aave:USDC	0.04897043	2025-09-07 23:28:25.735+00	2025-09-07 23:28:28.078357+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.078357+00
668	aave:USDC	0.00516494	2025-09-07 23:28:25.735+00	2025-09-07 23:28:28.081616+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.081616+00
669	justlend:USDD	0.00015849	2025-09-07 23:28:26.048+00	2025-09-07 23:28:28.084737+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.084737+00
670	justlend:USDT	0.11206852	2025-09-07 23:28:26.048+00	2025-09-07 23:28:28.087847+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.087847+00
671	stride:stATOM	0.12000000	2025-09-07 23:28:25.738+00	2025-09-07 23:28:28.092709+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.092709+00
672	stride:stTIA	0.14000000	2025-09-07 23:28:25.738+00	2025-09-07 23:28:28.096303+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:28:28.096303+00
790	aave:USDT	0.04270751	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.194147+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.194147+00
791	aave:USDC	0.02116635	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.198746+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.198746+00
792	aave:DAI	0.03628603	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.202603+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.202603+00
793	aave:USDT	0.04160546	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.206512+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.206512+00
794	aave:USDC	0.06679407	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.210155+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.210155+00
795	aave:USDC	0.05038347	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.213332+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.213332+00
796	aave:DAI	0.03431939	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.217141+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.217141+00
797	aave:USDT	0.03144053	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.220955+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.220955+00
798	aave:USDC	0.06056231	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.224899+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.224899+00
799	aave:USDC	0.02546324	2025-09-09 22:12:20.156+00	2025-09-09 22:12:22.228782+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.228782+00
800	justlend:USDD	0.00001425	2025-09-09 22:12:20.417+00	2025-09-09 22:12:22.23267+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.23267+00
801	justlend:USDT	0.01469671	2025-09-09 22:12:20.417+00	2025-09-09 22:12:22.236857+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.236857+00
802	stride:stATOM	0.12000000	2025-09-09 22:12:20.159+00	2025-09-09 22:12:22.241792+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.241792+00
803	stride:stTIA	0.14000000	2025-09-09 22:12:20.159+00	2025-09-09 22:12:22.245417+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:12:22.245417+00
931	aave:DAI	0.03626047	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:56:58.428642+00
676	aave:AUSD	0.05223551	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	avalanche	AUSD	0.05361991715000802	\N	\N	onchain	2025-09-07 23:28:28.307635+00
673	aave:USDT	0.04242915	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:28:28.332531+00
677	aave:USDT	0.03724569	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:28:28.332531+00
680	aave:USDT	0.02844440	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:28:28.332531+00
675	aave:DAI	0.03575518	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:28:28.33854+00
681	aave:DAI	0.03463319	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:28:28.33854+00
807	aave:AUSD	0.05061662	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	avalanche	AUSD	0.05191583637480823	\N	\N	onchain	2025-09-09 22:12:22.437077+00
674	aave:USDC	0.02405281	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:28:28.347844+00
678	aave:USDC	0.05528768	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:28:28.347844+00
679	aave:USDC	0.04899767	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:28:28.347844+00
682	aave:USDC	0.04897043	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:28:28.347844+00
683	aave:USDC	0.00516494	2025-09-07 23:28:25.706+00	2025-09-07 23:28:28.277841+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:28:28.347844+00
684	justlend:USDD	0.00015849	2025-09-07 23:28:26.047+00	2025-09-07 23:28:28.277841+00	justlend	tron	USDD	0.00015850205486689362	\N	0	justlend	2025-09-07 23:28:28.35212+00
685	justlend:USDT	0.11206852	2025-09-07 23:28:26.047+00	2025-09-07 23:28:28.277841+00	justlend	tron	USDT	0.11857026333464793	\N	0	justlend	2025-09-07 23:28:28.357717+00
686	stride:stATOM	0.12000000	2025-09-07 23:28:25.73+00	2025-09-07 23:28:28.277841+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-07 23:28:28.362673+00
687	stride:stTIA	0.14000000	2025-09-07 23:28:25.73+00	2025-09-07 23:28:28.277841+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-07 23:28:28.367203+00
806	aave:DAI	0.03628603	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	ethereum	DAI	0.0349151	\N	\N	llama	2025-09-09 22:12:22.444003+00
811	aave:DAI	0.03431939	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	ethereum	DAI	0.0349151	\N	\N	llama	2025-09-09 22:12:22.444003+00
804	aave:USDT	0.04270751	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	avalanche	USDT	0.031939999999999996	\N	\N	llama	2025-09-09 22:12:22.445532+00
808	aave:USDT	0.04160546	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	avalanche	USDT	0.031939999999999996	\N	\N	llama	2025-09-09 22:12:22.445532+00
812	aave:USDT	0.03144053	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	avalanche	USDT	0.031939999999999996	\N	\N	llama	2025-09-09 22:12:22.445532+00
805	aave:USDC	0.02116635	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:12:22.4491+00
809	aave:USDC	0.06679407	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:12:22.4491+00
810	aave:USDC	0.05038347	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:12:22.4491+00
813	aave:USDC	0.06056231	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:12:22.4491+00
814	aave:USDC	0.02546324	2025-09-09 22:12:20.161+00	2025-09-09 22:12:22.421639+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:12:22.4491+00
815	justlend:USDD	0.00001425	2025-09-09 22:12:20.441+00	2025-09-09 22:12:22.421639+00	justlend	tron	USDD	1.4253374686079567e-05	\N	0	justlend	2025-09-09 22:12:22.451187+00
816	justlend:USDT	0.01469671	2025-09-09 22:12:20.441+00	2025-09-09 22:12:22.421639+00	justlend	tron	USDT	0.014804933671608955	\N	0	justlend	2025-09-09 22:12:22.453146+00
817	stride:stATOM	0.12000000	2025-09-09 22:12:20.163+00	2025-09-09 22:12:22.421639+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-09 22:12:22.454984+00
818	stride:stTIA	0.14000000	2025-09-09 22:12:20.163+00	2025-09-09 22:12:22.421639+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-09 22:12:22.456909+00
903	aave:USDC	0.02546275	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:55:55.073365+00
914	aave:AUSD	0.05174753	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:56:03.394702+00
913	aave:DAI	0.03626047	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:56:03.404264+00
918	aave:DAI	0.03471461	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:56:03.404264+00
911	aave:USDT	0.04434195	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:56:03.406104+00
915	aave:USDT	0.04198199	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:56:03.406104+00
912	aave:USDC	0.02116666	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:03.410445+00
916	aave:USDC	0.04559707	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:03.410445+00
922	justlend:USDD	0.00001436	2025-09-10 01:56:01.562+00	2025-09-10 01:56:03.380692+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:56:03.412292+00
819	aave:USDT	0.04270914	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.516908+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.516908+00
820	aave:USDC	0.02115899	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.566285+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.566285+00
821	aave:DAI	0.03628603	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.570576+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.570576+00
822	aave:USDT	0.04196502	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.57551+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.57551+00
823	aave:USDC	0.04579521	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.580375+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.580375+00
824	aave:USDC	0.05031386	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.583304+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.583304+00
825	aave:DAI	0.03431939	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.587197+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.587197+00
826	aave:USDT	0.03152716	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.590841+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.590841+00
827	aave:USDC	0.06061512	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.593896+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.593896+00
828	aave:USDC	0.02546324	2025-09-09 22:24:15.604+00	2025-09-09 22:24:17.597748+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.597748+00
829	justlend:USDD	0.00001425	2025-09-09 22:24:15.911+00	2025-09-09 22:24:17.600112+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.600112+00
830	justlend:USDT	0.01469671	2025-09-09 22:24:15.911+00	2025-09-09 22:24:17.628081+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.628081+00
831	stride:stATOM	0.12000000	2025-09-09 22:24:15.607+00	2025-09-09 22:24:17.63256+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.63256+00
832	stride:stTIA	0.14000000	2025-09-09 22:24:15.607+00	2025-09-09 22:24:17.636014+00	\N	\N	\N	\N	\N	\N	\N	2025-09-09 22:24:17.636014+00
1166	aave:AUSD	0.13780779	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	avalanche	AUSD	0.14772506918770545	\N	\N	onchain	2025-09-10 16:58:57.915043+00
691	aave:AUSD	0.05221685	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	avalanche	AUSD	0.05360025775432642	\N	\N	onchain	2025-09-07 23:41:30.841521+00
1058	aave:AUSD	0.05158318	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	avalanche	AUSD	0.05293292587335818	\N	\N	onchain	2025-09-10 02:21:17.663312+00
1057	aave:DAI	0.03626048	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:21:17.673866+00
1062	aave:DAI	0.03471461	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:21:17.673866+00
919	aave:USDT	0.03161591	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:56:03.406104+00
1056	aave:USDC	0.02116666	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.680217+00
917	aave:USDC	0.04983562	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:03.410445+00
920	aave:USDC	0.06175405	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:03.410445+00
921	aave:USDC	0.02546275	2025-09-10 01:56:01.347+00	2025-09-10 01:56:03.380692+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:03.410445+00
688	aave:USDT	0.04242528	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:41:30.857583+00
692	aave:USDT	0.03724569	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:41:30.857583+00
695	aave:USDT	0.02844440	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:41:30.857583+00
690	aave:DAI	0.03575469	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:41:30.862535+00
696	aave:DAI	0.03463319	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:41:30.862535+00
923	justlend:USDT	0.01458957	2025-09-10 01:56:01.562+00	2025-09-10 01:56:03.380692+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 01:56:03.416746+00
924	stride:stATOM	0.15140000	2025-09-10 01:56:01.349+00	2025-09-10 01:56:03.380692+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:56:03.420033+00
925	stride:stTIA	0.11000000	2025-09-10 01:56:01.349+00	2025-09-10 01:56:03.380692+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:56:03.422983+00
926	stride:stJUNO	0.22620000	2025-09-10 01:56:01.349+00	2025-09-10 01:56:03.380692+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 01:56:03.424731+00
927	stride:stLUNA	0.17720000	2025-09-10 01:56:01.349+00	2025-09-10 01:56:03.380692+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 01:56:03.427268+00
689	aave:USDC	0.02405287	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:41:30.871443+00
693	aave:USDC	0.05528768	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:41:30.871443+00
694	aave:USDC	0.04899767	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:41:30.871443+00
697	aave:USDC	0.04897043	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:41:30.871443+00
698	aave:USDC	0.00516494	2025-09-07 23:41:28.963+00	2025-09-07 23:41:30.735993+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:41:30.871443+00
699	justlend:USDD	0.00016133	2025-09-07 23:41:29.032+00	2025-09-07 23:41:30.735993+00	justlend	tron	USDD	0.00016134599378303527	\N	0	justlend	2025-09-07 23:41:30.87674+00
700	justlend:USDT	0.03484288	2025-09-07 23:41:29.032+00	2025-09-07 23:41:30.735993+00	justlend	tron	USDT	0.03545528343711668	\N	0	justlend	2025-09-07 23:41:30.882197+00
701	stride:stATOM	0.12000000	2025-09-07 23:41:28.964+00	2025-09-07 23:41:30.735993+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-07 23:41:30.887444+00
702	stride:stTIA	0.14000000	2025-09-07 23:41:28.964+00	2025-09-07 23:41:30.735993+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-07 23:41:30.893199+00
928	stride:stBAND	0.15430000	2025-09-10 01:56:01.349+00	2025-09-10 01:56:03.380692+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 01:56:03.429098+00
932	aave:AUSD	0.05174753	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:56:58.423449+00
936	aave:DAI	0.03471461	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:56:58.428642+00
929	aave:USDT	0.04434237	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:56:58.42991+00
933	aave:USDT	0.04198199	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:56:58.42991+00
937	aave:USDT	0.03161591	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:56:58.42991+00
930	aave:USDC	0.02116666	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:58.432483+00
934	aave:USDC	0.04559707	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:58.432483+00
935	aave:USDC	0.04983562	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:58.432483+00
938	aave:USDC	0.06175405	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:58.432483+00
939	aave:USDC	0.02546275	2025-09-10 01:56:56.765+00	2025-09-10 01:56:58.411794+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:56:58.432483+00
940	justlend:USDD	0.00001436	2025-09-10 01:56:56.97+00	2025-09-10 01:56:58.411794+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:56:58.433915+00
941	justlend:USDT	0.01458957	2025-09-10 01:56:56.97+00	2025-09-10 01:56:58.411794+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 01:56:58.436103+00
942	stride:stATOM	0.15140000	2025-09-10 01:56:56.767+00	2025-09-10 01:56:58.411794+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:56:58.437657+00
943	stride:stTIA	0.11000000	2025-09-10 01:56:56.767+00	2025-09-10 01:56:58.411794+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:56:58.445857+00
944	stride:stJUNO	0.22620000	2025-09-10 01:56:56.767+00	2025-09-10 01:56:58.411794+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 01:56:58.447157+00
945	stride:stLUNA	0.17720000	2025-09-10 01:56:56.767+00	2025-09-10 01:56:58.411794+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 01:56:58.448414+00
946	stride:stBAND	0.15430000	2025-09-10 01:56:56.767+00	2025-09-10 01:56:58.411794+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 01:56:58.449798+00
1026	aave:DAI	0.03471461	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:04:45.14229+00
1023	aave:USDT	0.04198199	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:45.148772+00
1027	aave:USDT	0.03161591	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:45.148772+00
703	aave:USDT	0.04247847	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.235815+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.235815+00
704	aave:USDC	0.02405287	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.253682+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.253682+00
705	aave:DAI	0.03575469	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.3218+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.3218+00
706	aave:USDT	0.03724569	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.32634+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.32634+00
707	aave:USDC	0.05528768	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.331169+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.331169+00
708	aave:USDC	0.04899767	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.33542+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.33542+00
709	aave:USDT	0.02844440	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.340922+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.340922+00
710	aave:DAI	0.03463319	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.345763+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.345763+00
711	aave:USDC	0.04897043	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.350777+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.350777+00
712	aave:USDC	0.00516494	2025-09-07 23:51:24.182+00	2025-09-07 23:51:26.354363+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.354363+00
715	stride:stATOM	0.12000000	2025-09-07 23:51:24.183+00	2025-09-07 23:51:26.365837+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.365837+00
716	stride:stTIA	0.14000000	2025-09-07 23:51:24.183+00	2025-09-07 23:51:26.37063+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:51:26.37063+00
836	aave:AUSD	0.05061388	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	avalanche	AUSD	0.05191295601619084	\N	\N	onchain	2025-09-09 22:24:17.936182+00
720	aave:AUSD	0.05217875	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	avalanche	AUSD	0.053560121472338684	\N	\N	onchain	2025-09-07 23:51:26.668962+00
950	aave:AUSD	0.05174753	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:59:19.917369+00
835	aave:DAI	0.03628603	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	ethereum	DAI	0.0349151	\N	\N	llama	2025-09-09 22:24:17.943807+00
717	aave:USDT	0.04247847	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:51:26.685017+00
721	aave:USDT	0.03724569	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:51:26.685017+00
724	aave:USDT	0.02844440	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:51:26.685017+00
719	aave:DAI	0.03575469	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:51:26.689969+00
725	aave:DAI	0.03463319	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:51:26.689969+00
840	aave:DAI	0.03431939	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	ethereum	DAI	0.0349151	\N	\N	llama	2025-09-09 22:24:17.943807+00
833	aave:USDT	0.04270914	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	avalanche	USDT	0.0320294	\N	\N	llama	2025-09-09 22:24:17.945897+00
837	aave:USDT	0.04196502	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	avalanche	USDT	0.0320294	\N	\N	llama	2025-09-09 22:24:17.945897+00
841	aave:USDT	0.03152716	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	avalanche	USDT	0.0320294	\N	\N	llama	2025-09-09 22:24:17.945897+00
718	aave:USDC	0.02405287	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:51:26.697748+00
722	aave:USDC	0.05528768	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:51:26.697748+00
723	aave:USDC	0.04899767	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:51:26.697748+00
726	aave:USDC	0.04897043	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:51:26.697748+00
727	aave:USDC	0.00516494	2025-09-07 23:51:24.178+00	2025-09-07 23:51:26.645548+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:51:26.697748+00
713	justlend:USDD	0.00016133	2025-09-07 23:51:24.525+00	2025-09-07 23:51:26.358027+00	justlend	tron	USDD	0.00016134599378303527	\N	0	justlend	2025-09-07 23:51:26.701481+00
728	justlend:USDD	0.00016133	2025-09-07 23:51:24.525+00	2025-09-07 23:51:26.645548+00	justlend	tron	USDD	0.00016134599378303527	\N	0	justlend	2025-09-07 23:51:26.701481+00
714	justlend:USDT	0.03535576	2025-09-07 23:51:24.525+00	2025-09-07 23:51:26.361709+00	justlend	tron	USDT	0.03598643561389392	\N	0	justlend	2025-09-07 23:51:26.712062+00
729	justlend:USDT	0.03535576	2025-09-07 23:51:24.525+00	2025-09-07 23:51:26.645548+00	justlend	tron	USDT	0.03598643561389392	\N	0	justlend	2025-09-07 23:51:26.712062+00
730	stride:stATOM	0.12000000	2025-09-07 23:51:24.18+00	2025-09-07 23:51:26.645548+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-07 23:51:26.717062+00
731	stride:stTIA	0.14000000	2025-09-07 23:51:24.18+00	2025-09-07 23:51:26.645548+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-07 23:51:26.720409+00
949	aave:DAI	0.03626048	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:59:19.936438+00
834	aave:USDC	0.02115899	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:24:17.951502+00
838	aave:USDC	0.04579521	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:24:17.951502+00
839	aave:USDC	0.05031386	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:24:17.951502+00
842	aave:USDC	0.06061512	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:24:17.951502+00
843	aave:USDC	0.02546324	2025-09-09 22:24:15.586+00	2025-09-09 22:24:17.915255+00	aave	celo	USDC	0.0257902	\N	\N	llama	2025-09-09 22:24:17.951502+00
844	justlend:USDD	0.00001425	2025-09-09 22:24:15.896+00	2025-09-09 22:24:17.915255+00	justlend	tron	USDD	1.4253374686079567e-05	\N	0	justlend	2025-09-09 22:24:17.953244+00
845	justlend:USDT	0.01469671	2025-09-09 22:24:15.896+00	2025-09-09 22:24:17.915255+00	justlend	tron	USDT	0.014804933671608955	\N	0	justlend	2025-09-09 22:24:17.954906+00
846	stride:stATOM	0.12000000	2025-09-09 22:24:15.601+00	2025-09-09 22:24:17.915255+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-09 22:24:17.956976+00
847	stride:stTIA	0.14000000	2025-09-09 22:24:15.601+00	2025-09-09 22:24:17.915255+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-09 22:24:17.959582+00
954	aave:DAI	0.03471461	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:59:19.936438+00
947	aave:USDT	0.04434237	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:19.941193+00
951	aave:USDT	0.04198199	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:19.941193+00
955	aave:USDT	0.03161591	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:19.941193+00
948	aave:USDC	0.02116666	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.950935+00
952	aave:USDC	0.04559707	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.950935+00
953	aave:USDC	0.04983562	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.950935+00
956	aave:USDC	0.06175405	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.950935+00
957	aave:USDC	0.02546275	2025-09-10 01:59:17.657+00	2025-09-10 01:59:19.815203+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.950935+00
960	stride:stATOM	0.15140000	2025-09-10 01:59:17.658+00	2025-09-10 01:59:19.815203+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:59:19.96597+00
961	stride:stTIA	0.11000000	2025-09-10 01:59:17.658+00	2025-09-10 01:59:19.815203+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:59:19.971384+00
962	stride:stJUNO	0.22620000	2025-09-10 01:59:17.658+00	2025-09-10 01:59:19.815203+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 01:59:19.976156+00
963	stride:stLUNA	0.17720000	2025-09-10 01:59:17.658+00	2025-09-10 01:59:19.815203+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 01:59:19.981039+00
958	justlend:USDD	0.00001436	2025-09-10 01:59:17.882+00	2025-09-10 01:59:19.815203+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:59:19.983236+00
964	stride:stBAND	0.15430000	2025-09-10 01:59:17.658+00	2025-09-10 01:59:19.815203+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 01:59:19.985797+00
959	justlend:USDT	0.01458957	2025-09-10 01:59:17.882+00	2025-09-10 01:59:19.815203+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 01:59:19.987991+00
1030	justlend:USDD	0.00001436	2025-09-10 02:04:40.416+00	2025-09-10 02:04:45.0411+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 02:04:45.174107+00
732	aave:USDT	0.04254461	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.147026+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.147026+00
733	aave:USDC	0.02405287	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.154554+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.154554+00
734	aave:DAI	0.03575469	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.159253+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.159253+00
735	aave:USDT	0.03724569	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.163589+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.163589+00
736	aave:USDC	0.05528768	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.168213+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.168213+00
737	aave:USDC	0.04899767	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.172612+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.172612+00
738	aave:USDT	0.02844440	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.176974+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.176974+00
739	aave:DAI	0.03463319	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.181314+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.181314+00
740	aave:USDC	0.04897043	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.186035+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.186035+00
741	aave:USDC	0.00516494	2025-09-07 23:57:58.779+00	2025-09-07 23:58:01.190406+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.190406+00
742	justlend:USDD	0.00016081	2025-09-07 23:57:59.008+00	2025-09-07 23:58:01.195272+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.195272+00
743	justlend:USDT	0.03535576	2025-09-07 23:57:59.008+00	2025-09-07 23:58:01.201641+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.201641+00
744	stride:stATOM	0.12000000	2025-09-07 23:57:58.78+00	2025-09-07 23:58:01.206166+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.206166+00
745	stride:stTIA	0.14000000	2025-09-07 23:57:58.78+00	2025-09-07 23:58:01.210226+00	\N	\N	\N	\N	\N	\N	\N	2025-09-07 23:58:01.210226+00
749	aave:AUSD	0.05217842	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	avalanche	AUSD	0.05355977298330861	\N	\N	onchain	2025-09-07 23:58:01.48545+00
851	aave:AUSD	0.05174753	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:40:09.581728+00
968	aave:AUSD	0.05174753	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:59:19.943124+00
746	aave:USDT	0.04254461	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:58:01.50134+00
750	aave:USDT	0.03724569	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:58:01.50134+00
753	aave:USDT	0.02844440	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	avalanche	USDT	0.028852799999999998	\N	\N	llama	2025-09-07 23:58:01.50134+00
748	aave:DAI	0.03575469	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:58:01.506372+00
754	aave:DAI	0.03463319	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	ethereum	DAI	0.0352399	\N	\N	llama	2025-09-07 23:58:01.506372+00
850	aave:DAI	0.03628624	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:40:09.587555+00
855	aave:DAI	0.03471461	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:40:09.587555+00
848	aave:USDT	0.04280807	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:40:09.589199+00
852	aave:USDT	0.04198199	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:40:09.589199+00
747	aave:USDC	0.02405287	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:58:01.516417+00
751	aave:USDC	0.05528768	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:58:01.516417+00
752	aave:USDC	0.04899767	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:58:01.516417+00
755	aave:USDC	0.04897043	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:58:01.516417+00
756	aave:USDC	0.00516494	2025-09-07 23:57:58.775+00	2025-09-07 23:58:01.459877+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-07 23:58:01.516417+00
757	justlend:USDD	0.00016081	2025-09-07 23:57:59.001+00	2025-09-07 23:58:01.459877+00	justlend	tron	USDD	0.00016082739558953563	\N	0	justlend	2025-09-07 23:58:01.520154+00
758	justlend:USDT	0.03535576	2025-09-07 23:57:59.001+00	2025-09-07 23:58:01.459877+00	justlend	tron	USDT	0.03598643561389392	\N	0	justlend	2025-09-07 23:58:01.524124+00
759	stride:stATOM	0.12000000	2025-09-07 23:57:58.777+00	2025-09-07 23:58:01.459877+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-07 23:58:01.528257+00
760	stride:stTIA	0.14000000	2025-09-07 23:57:58.777+00	2025-09-07 23:58:01.459877+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-07 23:58:01.531219+00
856	aave:USDT	0.03161591	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:40:09.589199+00
849	aave:USDC	0.02116653	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:40:09.592937+00
853	aave:USDC	0.04559707	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:40:09.592937+00
854	aave:USDC	0.04983562	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:40:09.592937+00
857	aave:USDC	0.06175405	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:40:09.592937+00
858	aave:USDC	0.02546275	2025-09-10 01:40:07.935+00	2025-09-10 01:40:09.570374+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:40:09.592937+00
859	justlend:USDD	0.00001436	2025-09-10 01:40:08.175+00	2025-09-10 01:40:09.570374+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:40:09.594828+00
860	justlend:USDT	0.01464389	2025-09-10 01:40:08.175+00	2025-09-10 01:40:09.570374+00	justlend	tron	USDT	0.014751334739702804	\N	0	justlend	2025-09-10 01:40:09.598264+00
861	stride:stATOM	0.12000000	2025-09-10 01:40:07.937+00	2025-09-10 01:40:09.570374+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-10 01:40:09.603815+00
862	stride:stTIA	0.14000000	2025-09-10 01:40:07.937+00	2025-09-10 01:40:09.570374+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-10 01:40:09.607179+00
967	aave:DAI	0.03626048	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:59:19.962842+00
972	aave:DAI	0.03471461	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:59:19.962842+00
965	aave:USDT	0.04434237	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:19.968634+00
969	aave:USDT	0.04198199	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:19.968634+00
973	aave:USDT	0.03161591	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:19.968634+00
966	aave:USDC	0.02116666	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.97883+00
970	aave:USDC	0.04559707	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.97883+00
971	aave:USDC	0.04983562	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.97883+00
974	aave:USDC	0.06175405	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.97883+00
975	aave:USDC	0.02546275	2025-09-10 01:59:17.651+00	2025-09-10 01:59:19.921838+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:19.97883+00
976	justlend:USDD	0.00001436	2025-09-10 01:59:17.882+00	2025-09-10 01:59:19.921838+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:59:19.983236+00
977	justlend:USDT	0.01458957	2025-09-10 01:59:17.882+00	2025-09-10 01:59:19.921838+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 01:59:19.987991+00
978	stride:stATOM	0.15140000	2025-09-10 01:59:17.656+00	2025-09-10 01:59:19.921838+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:59:19.992864+00
979	stride:stTIA	0.11000000	2025-09-10 01:59:17.656+00	2025-09-10 01:59:19.921838+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:59:19.995901+00
980	stride:stJUNO	0.22620000	2025-09-10 01:59:17.656+00	2025-09-10 01:59:19.921838+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 01:59:20.000023+00
981	stride:stLUNA	0.17720000	2025-09-10 01:59:17.656+00	2025-09-10 01:59:19.921838+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 01:59:20.004323+00
982	stride:stBAND	0.15430000	2025-09-10 01:59:17.656+00	2025-09-10 01:59:19.921838+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 01:59:20.007693+00
985	aave:DAI	0.03626048	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:59:20.102666+00
983	aave:USDT	0.04434237	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:20.106225+00
986	aave:AUSD	0.05174753	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:59:20.088313+00
764	aave:AUSD	0.05214239	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	avalanche	AUSD	0.05352182278933859	\N	\N	onchain	2025-09-08 01:05:28.935273+00
866	aave:AUSD	0.05174753	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:45:11.031065+00
990	aave:DAI	0.03471461	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:59:20.102666+00
761	aave:USDT	0.04254764	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	avalanche	USDT	0.0290618	\N	\N	llama	2025-09-08 01:05:28.954699+00
765	aave:USDT	0.03720965	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	avalanche	USDT	0.0290618	\N	\N	llama	2025-09-08 01:05:28.954699+00
768	aave:USDT	0.02864751	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	avalanche	USDT	0.0290618	\N	\N	llama	2025-09-08 01:05:28.954699+00
763	aave:DAI	0.03575474	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	ethereum	DAI	0.0352402	\N	\N	llama	2025-09-08 01:05:28.959361+00
769	aave:DAI	0.03463348	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	ethereum	DAI	0.0352402	\N	\N	llama	2025-09-08 01:05:28.959361+00
987	aave:USDT	0.04198199	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:20.106225+00
865	aave:DAI	0.03628624	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:45:11.047447+00
870	aave:DAI	0.03471461	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:45:11.047447+00
863	aave:USDT	0.04290135	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:45:11.049958+00
867	aave:USDT	0.04198199	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:45:11.049958+00
762	aave:USDC	0.02405292	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-08 01:05:28.968347+00
766	aave:USDC	0.05528768	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-08 01:05:28.968347+00
767	aave:USDC	0.04887768	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-08 01:05:28.968347+00
770	aave:USDC	0.04922026	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-08 01:05:28.968347+00
771	aave:USDC	0.00516494	2025-09-08 01:05:26.216+00	2025-09-08 01:05:28.906063+00	aave	celo	USDC	0.0051783	\N	\N	llama	2025-09-08 01:05:28.968347+00
772	justlend:USDD	0.00001620	2025-09-08 01:05:26.468+00	2025-09-08 01:05:28.906063+00	justlend	tron	USDD	1.6195412053221503e-05	\N	0	justlend	2025-09-08 01:05:28.972821+00
773	justlend:USDT	0.03439341	2025-09-08 01:05:26.468+00	2025-09-08 01:05:28.906063+00	justlend	tron	USDT	0.034990028836955345	\N	0	justlend	2025-09-08 01:05:28.977215+00
774	stride:stATOM	0.12000000	2025-09-08 01:05:26.22+00	2025-09-08 01:05:28.906063+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-08 01:05:28.982054+00
775	stride:stTIA	0.14000000	2025-09-08 01:05:26.22+00	2025-09-08 01:05:28.906063+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-08 01:05:28.986782+00
776	aave:USDT	0.04254764	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.057482+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.057482+00
777	aave:USDC	0.02405292	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.063871+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.063871+00
778	aave:DAI	0.03575474	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.069367+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.069367+00
779	aave:USDT	0.03720965	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.074787+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.074787+00
780	aave:USDC	0.05528768	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.079418+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.079418+00
781	aave:USDC	0.04887768	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.083808+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.083808+00
782	aave:USDT	0.02864751	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.088163+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.088163+00
783	aave:DAI	0.03463348	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.093955+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.093955+00
784	aave:USDC	0.04922026	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.099774+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.099774+00
785	aave:USDC	0.00516494	2025-09-08 01:05:26.227+00	2025-09-08 01:05:29.104869+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.104869+00
786	justlend:USDD	0.00001620	2025-09-08 01:05:26.708+00	2025-09-08 01:05:29.109658+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.109658+00
787	justlend:USDT	0.03439341	2025-09-08 01:05:26.708+00	2025-09-08 01:05:29.113856+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.113856+00
788	stride:stATOM	0.12000000	2025-09-08 01:05:26.229+00	2025-09-08 01:05:29.119285+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.119285+00
871	aave:USDT	0.03161591	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:45:11.049958+00
991	aave:USDT	0.03161591	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:59:20.106225+00
864	aave:USDC	0.02116653	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:45:11.054112+00
868	aave:USDC	0.04559707	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:45:11.054112+00
869	aave:USDC	0.04983562	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:45:11.054112+00
872	aave:USDC	0.06175405	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:45:11.054112+00
873	aave:USDC	0.02546275	2025-09-10 01:45:08.971+00	2025-09-10 01:45:11.018018+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:45:11.054112+00
874	justlend:USDD	0.00001436	2025-09-10 01:45:09.239+00	2025-09-10 01:45:11.018018+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:45:11.056843+00
875	justlend:USDT	0.01464389	2025-09-10 01:45:09.239+00	2025-09-10 01:45:11.018018+00	justlend	tron	USDT	0.014751334739702804	\N	0	justlend	2025-09-10 01:45:11.059465+00
876	stride:stATOM	0.12000000	2025-09-10 01:45:08.973+00	2025-09-10 01:45:11.018018+00	stride	cosmos	stATOM	0.12747461563840012	\N	\N	stride	2025-09-10 01:45:11.061478+00
877	stride:stTIA	0.14000000	2025-09-10 01:45:08.973+00	2025-09-10 01:45:11.018018+00	stride	cosmos	stTIA	0.1502429231030309	\N	\N	stride	2025-09-10 01:45:11.063478+00
984	aave:USDC	0.02116666	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:20.112187+00
988	aave:USDC	0.04559707	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:20.112187+00
989	aave:USDC	0.04983562	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:20.112187+00
992	aave:USDC	0.06175405	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:20.112187+00
993	aave:USDC	0.02546275	2025-09-10 01:59:17.661+00	2025-09-10 01:59:20.068319+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:59:20.112187+00
994	justlend:USDD	0.00001436	2025-09-10 01:59:17.938+00	2025-09-10 01:59:20.068319+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:59:20.116119+00
995	justlend:USDT	0.01458957	2025-09-10 01:59:17.938+00	2025-09-10 01:59:20.068319+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 01:59:20.119493+00
996	stride:stATOM	0.15140000	2025-09-10 01:59:17.662+00	2025-09-10 01:59:20.068319+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:59:20.123316+00
997	stride:stTIA	0.11000000	2025-09-10 01:59:17.662+00	2025-09-10 01:59:20.068319+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:59:20.127477+00
998	stride:stJUNO	0.22620000	2025-09-10 01:59:17.662+00	2025-09-10 01:59:20.068319+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 01:59:20.131955+00
999	stride:stLUNA	0.17720000	2025-09-10 01:59:17.662+00	2025-09-10 01:59:20.068319+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 01:59:20.136423+00
1000	stride:stBAND	0.15430000	2025-09-10 01:59:17.662+00	2025-09-10 01:59:20.068319+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 01:59:20.140749+00
1019	aave:USDT	0.04434449	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:45.148772+00
1032	stride:stATOM	0.15140000	2025-09-10 02:04:40.005+00	2025-09-10 02:04:45.0411+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 02:04:45.190822+00
1033	stride:stTIA	0.11000000	2025-09-10 02:04:40.005+00	2025-09-10 02:04:45.0411+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 02:04:45.196268+00
1035	stride:stLUNA	0.17720000	2025-09-10 02:04:40.005+00	2025-09-10 02:04:45.0411+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 02:04:45.207624+00
1036	stride:stBAND	0.15430000	2025-09-10 02:04:40.005+00	2025-09-10 02:04:45.0411+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 02:04:45.213922+00
789	stride:stTIA	0.14000000	2025-09-08 01:05:26.229+00	2025-09-08 01:05:29.12407+00	\N	\N	\N	\N	\N	\N	\N	2025-09-08 01:05:29.12407+00
1068	stride:stATOM	0.15140000	2025-09-10 02:21:15.991+00	2025-09-10 02:21:17.542773+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 02:21:17.686808+00
1070	stride:stJUNO	0.22620000	2025-09-10 02:21:15.991+00	2025-09-10 02:21:17.542773+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 02:21:17.690631+00
1071	stride:stLUNA	0.17720000	2025-09-10 02:21:15.991+00	2025-09-10 02:21:17.542773+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 02:21:17.692509+00
881	aave:AUSD	0.05174753	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:49:03.281953+00
1004	aave:AUSD	0.05159491	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	avalanche	AUSD	0.05294527636181434	\N	\N	onchain	2025-09-10 02:04:44.908469+00
880	aave:DAI	0.03627462	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:49:03.289972+00
885	aave:DAI	0.03471461	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:49:03.289972+00
878	aave:USDT	0.04434938	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:49:03.291465+00
882	aave:USDT	0.04198199	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:49:03.291465+00
886	aave:USDT	0.03161591	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:49:03.291465+00
1003	aave:DAI	0.03626048	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:04:44.925891+00
879	aave:USDC	0.02116653	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:49:03.295249+00
883	aave:USDC	0.04559707	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:49:03.295249+00
884	aave:USDC	0.04983562	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:49:03.295249+00
887	aave:USDC	0.06175405	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:49:03.295249+00
888	aave:USDC	0.02546275	2025-09-10 01:49:01.985+00	2025-09-10 01:49:03.2633+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:49:03.295249+00
889	justlend:USDD	0.00001436	2025-09-10 01:49:02.043+00	2025-09-10 01:49:03.2633+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:49:03.297284+00
890	justlend:USDT	0.01464389	2025-09-10 01:49:02.043+00	2025-09-10 01:49:03.2633+00	justlend	tron	USDT	0.014751334739702804	\N	0	justlend	2025-09-10 01:49:03.299774+00
891	stride:stATOM	0.15140000	2025-09-10 01:49:01.986+00	2025-09-10 01:49:03.2633+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:49:03.301812+00
892	stride:stTIA	0.11000000	2025-09-10 01:49:01.986+00	2025-09-10 01:49:03.2633+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:49:03.303827+00
1008	aave:DAI	0.03471461	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:04:44.925891+00
1001	aave:USDT	0.04434449	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:44.929762+00
1005	aave:USDT	0.04198199	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:44.929762+00
1009	aave:USDT	0.03161591	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:44.929762+00
1002	aave:USDC	0.02116666	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:44.936751+00
1006	aave:USDC	0.04559707	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:44.936751+00
1007	aave:USDC	0.04983562	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:44.936751+00
1010	aave:USDC	0.06175405	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:44.936751+00
1011	aave:USDC	0.02546275	2025-09-10 02:04:40.002+00	2025-09-10 02:04:44.8814+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:44.936751+00
1012	justlend:USDD	0.00001436	2025-09-10 02:04:40.214+00	2025-09-10 02:04:44.8814+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 02:04:44.939483+00
1013	justlend:USDT	0.01458957	2025-09-10 02:04:40.214+00	2025-09-10 02:04:44.8814+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 02:04:44.942197+00
1014	stride:stATOM	0.15140000	2025-09-10 02:04:40.003+00	2025-09-10 02:04:44.8814+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 02:04:44.944771+00
1015	stride:stTIA	0.11000000	2025-09-10 02:04:40.003+00	2025-09-10 02:04:44.8814+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 02:04:44.948243+00
1016	stride:stJUNO	0.22620000	2025-09-10 02:04:40.003+00	2025-09-10 02:04:44.8814+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 02:04:45.033474+00
1017	stride:stLUNA	0.17720000	2025-09-10 02:04:40.003+00	2025-09-10 02:04:44.8814+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 02:04:45.037004+00
1018	stride:stBAND	0.15430000	2025-09-10 02:04:40.003+00	2025-09-10 02:04:44.8814+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 02:04:45.041059+00
1021	aave:DAI	0.03626048	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:04:45.14229+00
1040	aave:AUSD	0.05159491	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	avalanche	AUSD	0.05294527636181434	\N	\N	onchain	2025-09-10 02:04:45.159924+00
1024	aave:USDC	0.04559707	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.166757+00
1025	aave:USDC	0.04983562	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.166757+00
1028	aave:USDC	0.06175405	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.166757+00
1029	aave:USDC	0.02546275	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.166757+00
1039	aave:DAI	0.03626048	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:04:45.192839+00
1044	aave:DAI	0.03471461	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:04:45.192839+00
1037	aave:USDT	0.04434449	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:45.199246+00
1041	aave:USDT	0.04198199	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:45.199246+00
1038	aave:USDC	0.02116666	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.211151+00
1042	aave:USDC	0.04559707	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.211151+00
1043	aave:USDC	0.04983562	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.211151+00
1046	aave:USDC	0.06175405	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.211151+00
1047	aave:USDC	0.02546275	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.211151+00
1048	justlend:USDD	0.00001436	2025-09-10 02:04:40.222+00	2025-09-10 02:04:45.127626+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 02:04:45.216426+00
1049	justlend:USDT	0.01458957	2025-09-10 02:04:40.222+00	2025-09-10 02:04:45.127626+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 02:04:45.222301+00
1050	stride:stATOM	0.15140000	2025-09-10 02:04:40+00	2025-09-10 02:04:45.127626+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 02:04:45.226558+00
1051	stride:stTIA	0.11000000	2025-09-10 02:04:40+00	2025-09-10 02:04:45.127626+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 02:04:45.230248+00
1052	stride:stJUNO	0.22620000	2025-09-10 02:04:40+00	2025-09-10 02:04:45.127626+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 02:04:45.234682+00
1053	stride:stLUNA	0.17720000	2025-09-10 02:04:40+00	2025-09-10 02:04:45.127626+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 02:04:45.238524+00
1054	stride:stBAND	0.15430000	2025-09-10 02:04:40+00	2025-09-10 02:04:45.127626+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 02:04:45.242006+00
1	stride:stATOM	0.12000000	2025-09-06 04:06:10.882+00	2025-09-06 04:06:11.342771+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
2	stride:stTIA	0.14000000	2025-09-06 04:06:10.882+00	2025-09-06 04:06:11.359156+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
3	stride:stATOM	0.12000000	2025-09-06 04:06:24.346+00	2025-09-06 04:06:24.729579+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
4	stride:stTIA	0.14000000	2025-09-06 04:06:24.346+00	2025-09-06 04:06:24.738565+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
5	stride:stATOM	0.12000000	2025-09-06 04:08:08.571+00	2025-09-06 04:08:09.067681+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
6	stride:stTIA	0.14000000	2025-09-06 04:08:08.571+00	2025-09-06 04:08:09.075454+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
7	stride:stATOM	0.12000000	2025-09-06 05:04:30.086+00	2025-09-06 05:04:30.496421+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
8	stride:stTIA	0.14000000	2025-09-06 05:04:30.086+00	2025-09-06 05:04:30.500576+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
9	stride:stATOM	0.12000000	2025-09-06 05:05:15.457+00	2025-09-06 05:05:16.462969+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
10	stride:stTIA	0.14000000	2025-09-06 05:05:15.457+00	2025-09-06 05:05:16.469494+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
11	stride:stATOM	0.12000000	2025-09-06 05:21:33.404+00	2025-09-06 05:21:33.873878+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
12	stride:stTIA	0.14000000	2025-09-06 05:21:33.404+00	2025-09-06 05:21:33.881688+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
13	stride:stATOM	0.12000000	2025-09-06 05:47:41.374+00	2025-09-06 05:47:41.655479+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
14	stride:stTIA	0.14000000	2025-09-06 05:47:41.374+00	2025-09-06 05:47:41.66254+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
15	aave:USDT	0.04241293	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
16	aave:USDC	0.02387908	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
17	aave:DAI	0.03495396	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
18	aave:USDT	0.04428575	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
19	aave:USDC	0.04759583	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
20	aave:USDC	0.04837465	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
21	aave:DAI	0.03327132	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
22	aave:USDT	0.02857356	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
23	aave:USDC	0.04856976	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
24	aave:USDC	0.00516136	2025-09-07 05:45:47.089+00	2025-09-07 05:45:48.78144+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
25	justlend:USDD	0.00001549	2025-09-07 05:45:47.378+00	2025-09-07 05:45:48.78144+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
26	justlend:USDT	0.02487397	2025-09-07 05:45:47.378+00	2025-09-07 05:45:48.78144+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
27	stride:stATOM	0.12000000	2025-09-07 05:45:47.114+00	2025-09-07 05:45:48.78144+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
28	stride:stTIA	0.14000000	2025-09-07 05:45:47.114+00	2025-09-07 05:45:48.78144+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
29	aave:USDT	0.04241294	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
30	aave:USDC	0.02387906	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
31	aave:DAI	0.03495402	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
32	aave:AUSD	0.11793274	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
33	aave:USDT	0.04428575	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
34	aave:USDC	0.04759583	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
35	aave:USDC	0.04837465	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
36	aave:DAI	0.03327132	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
37	aave:USDT	0.02857356	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
38	aave:USDC	0.04856976	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
39	aave:USDC	0.00516136	2025-09-07 05:49:51.563+00	2025-09-07 05:49:52.962582+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
40	justlend:USDD	0.00001549	2025-09-07 05:49:51.842+00	2025-09-07 05:49:52.962582+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
41	justlend:USDT	0.02487397	2025-09-07 05:49:51.842+00	2025-09-07 05:49:52.962582+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
42	stride:stATOM	0.12000000	2025-09-07 05:49:51.586+00	2025-09-07 05:49:52.962582+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
43	stride:stTIA	0.14000000	2025-09-07 05:49:51.586+00	2025-09-07 05:49:52.962582+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
44	aave:USDT	0.04241294	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.60572+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
45	aave:USDC	0.02387906	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.609631+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
46	aave:DAI	0.03495402	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.612325+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
47	aave:USDT	0.04428575	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.614139+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
48	aave:USDC	0.04759583	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.616067+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
49	aave:USDC	0.04837465	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.61802+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
50	aave:DAI	0.03327132	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.619567+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
51	aave:USDT	0.02857356	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.622228+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
52	aave:USDC	0.04856976	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.624106+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
53	aave:USDC	0.00516136	2025-09-07 05:50:51.28+00	2025-09-07 05:50:52.625538+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
54	justlend:USDD	0.00001549	2025-09-07 05:50:51.617+00	2025-09-07 05:50:52.62762+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
55	justlend:USDT	0.02487397	2025-09-07 05:50:51.617+00	2025-09-07 05:50:52.629173+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
56	stride:stATOM	0.12000000	2025-09-07 05:50:51.292+00	2025-09-07 05:50:52.630791+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
57	stride:stTIA	0.14000000	2025-09-07 05:50:51.292+00	2025-09-07 05:50:52.63272+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
58	aave:USDT	0.04241294	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
59	aave:USDC	0.02387906	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
60	aave:DAI	0.03495402	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
61	aave:AUSD	0.11793274	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
62	aave:USDT	0.04428575	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
63	aave:USDC	0.04759583	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
64	aave:USDC	0.04837465	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
65	aave:DAI	0.03327132	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
66	aave:USDT	0.02857356	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
67	aave:USDC	0.04856976	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
68	aave:USDC	0.00516136	2025-09-07 05:50:55.011+00	2025-09-07 05:50:56.137704+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
69	justlend:USDD	0.00001549	2025-09-07 05:50:55.067+00	2025-09-07 05:50:56.137704+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
70	justlend:USDT	0.02487397	2025-09-07 05:50:55.067+00	2025-09-07 05:50:56.137704+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
71	stride:stATOM	0.12000000	2025-09-07 05:50:55.012+00	2025-09-07 05:50:56.137704+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
72	stride:stTIA	0.14000000	2025-09-07 05:50:55.012+00	2025-09-07 05:50:56.137704+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
895	aave:DAI	0.03626047	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:55:55.066469+00
894	aave:USDC	0.02116666	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:55:55.073365+00
73	aave:USDT	0.04239928	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
74	aave:USDC	0.02403708	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
75	aave:DAI	0.03576982	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
76	aave:AUSD	0.05207173	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
77	aave:USDT	0.03446645	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
78	aave:USDC	0.05528768	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
79	aave:USDC	0.04887997	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
80	aave:USDT	0.02849911	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
81	aave:DAI	0.03439466	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
82	aave:USDC	0.04860700	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
83	aave:USDC	0.00534778	2025-09-07 18:21:04.19+00	2025-09-07 18:21:06.145822+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
84	justlend:USDD	0.00005180	2025-09-07 18:21:04.435+00	2025-09-07 18:21:06.145822+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
85	justlend:USDT	0.16802502	2025-09-07 18:21:04.435+00	2025-09-07 18:21:06.145822+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
86	stride:stATOM	0.12000000	2025-09-07 18:21:04.193+00	2025-09-07 18:21:06.145822+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
87	stride:stTIA	0.14000000	2025-09-07 18:21:04.193+00	2025-09-07 18:21:06.145822+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
88	aave:USDT	0.04239928	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
89	aave:USDC	0.02403708	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
90	aave:DAI	0.03576982	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
91	aave:AUSD	0.05207173	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
92	aave:USDT	0.03446645	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
93	aave:USDC	0.05528768	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
94	aave:USDC	0.04887997	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
95	aave:USDT	0.02849911	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
96	aave:DAI	0.03439466	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
97	aave:USDC	0.04860700	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
98	aave:USDC	0.00534778	2025-09-07 18:21:07.892+00	2025-09-07 18:21:09.079506+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
99	justlend:USDD	0.00005180	2025-09-07 18:21:07.947+00	2025-09-07 18:21:09.079506+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
100	justlend:USDT	0.16802502	2025-09-07 18:21:07.947+00	2025-09-07 18:21:09.079506+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
101	stride:stATOM	0.12000000	2025-09-07 18:21:07.893+00	2025-09-07 18:21:09.079506+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
102	stride:stTIA	0.14000000	2025-09-07 18:21:07.893+00	2025-09-07 18:21:09.079506+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
103	aave:USDT	0.04240056	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.868799+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
104	aave:USDC	0.02403708	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.875594+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
105	aave:DAI	0.03576958	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.878639+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
106	aave:USDT	0.03446297	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.881414+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
107	aave:USDC	0.05528768	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.883781+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
108	aave:USDC	0.04882521	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.885769+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
109	aave:USDT	0.02838248	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.888021+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
110	aave:DAI	0.03462488	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.893133+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
111	aave:USDC	0.04882597	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.895178+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
112	aave:USDC	0.00534778	2025-09-07 18:24:54.991+00	2025-09-07 18:24:56.897027+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
113	justlend:USDD	0.00009020	2025-09-07 18:24:55.212+00	2025-09-07 18:24:56.898959+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
114	justlend:USDT	0.17201357	2025-09-07 18:24:55.212+00	2025-09-07 18:24:56.901746+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
115	stride:stATOM	0.12000000	2025-09-07 18:24:54.994+00	2025-09-07 18:24:56.903956+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
116	stride:stTIA	0.14000000	2025-09-07 18:24:54.994+00	2025-09-07 18:24:56.905923+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
117	aave:USDT	0.04240056	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
118	aave:USDC	0.02403708	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
119	aave:DAI	0.03576958	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
120	aave:AUSD	0.05215303	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
121	aave:USDT	0.03446297	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
122	aave:USDC	0.05528768	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
123	aave:USDC	0.04882521	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
124	aave:USDT	0.02838248	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
125	aave:DAI	0.03462488	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
126	aave:USDC	0.04882597	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
127	aave:USDC	0.00534778	2025-09-07 18:24:54.982+00	2025-09-07 18:24:57.094787+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
128	justlend:USDD	0.00009020	2025-09-07 18:24:55.217+00	2025-09-07 18:24:57.094787+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
129	justlend:USDT	0.17201357	2025-09-07 18:24:55.217+00	2025-09-07 18:24:57.094787+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
130	stride:stATOM	0.12000000	2025-09-07 18:24:54.986+00	2025-09-07 18:24:57.094787+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
131	stride:stTIA	0.14000000	2025-09-07 18:24:54.986+00	2025-09-07 18:24:57.094787+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
132	aave:USDT	0.04239707	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
133	aave:USDC	0.02403708	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
134	aave:DAI	0.03576958	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
135	aave:AUSD	0.05223451	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
136	aave:USDT	0.03446297	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
137	aave:USDC	0.05528768	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
138	aave:USDC	0.04882521	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
139	aave:USDT	0.02838248	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
140	aave:DAI	0.03462488	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
141	aave:USDC	0.04882597	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
142	aave:USDC	0.00534778	2025-09-07 18:31:55.12+00	2025-09-07 18:31:57.071971+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
143	justlend:USDD	0.00011961	2025-09-07 18:31:55.4+00	2025-09-07 18:31:57.071971+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
144	justlend:USDT	0.16893895	2025-09-07 18:31:55.4+00	2025-09-07 18:31:57.071971+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
145	stride:stATOM	0.12000000	2025-09-07 18:31:55.124+00	2025-09-07 18:31:57.071971+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
146	stride:stTIA	0.14000000	2025-09-07 18:31:55.124+00	2025-09-07 18:31:57.071971+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
147	aave:USDT	0.04239708	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.871791+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
148	aave:USDC	0.02403436	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.879668+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
149	aave:DAI	0.03576958	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.88157+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
150	aave:USDT	0.03446297	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.883278+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
151	aave:USDC	0.05528768	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.884725+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
152	aave:USDC	0.04882521	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.886535+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
153	aave:USDT	0.02838248	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.888176+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
154	aave:DAI	0.03462488	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.890069+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
155	aave:USDC	0.04882597	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.892944+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
156	aave:USDC	0.00534778	2025-09-07 18:34:40.527+00	2025-09-07 18:34:41.894658+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
157	justlend:USDD	0.00011961	2025-09-07 18:34:40.814+00	2025-09-07 18:34:41.896392+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
158	justlend:USDT	0.16633919	2025-09-07 18:34:40.814+00	2025-09-07 18:34:41.898374+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
159	stride:stATOM	0.12000000	2025-09-07 18:34:40.529+00	2025-09-07 18:34:41.899845+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
160	stride:stTIA	0.14000000	2025-09-07 18:34:40.529+00	2025-09-07 18:34:41.901616+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
161	aave:USDT	0.04239708	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
162	aave:USDC	0.02403436	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
163	aave:DAI	0.03576958	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
164	aave:AUSD	0.05223451	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
165	aave:USDT	0.03446297	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
166	aave:USDC	0.05528768	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
167	aave:USDC	0.04882521	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
168	aave:USDT	0.02838248	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
169	aave:DAI	0.03462488	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
170	aave:USDC	0.04882597	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
171	aave:USDC	0.00534778	2025-09-07 18:34:40.519+00	2025-09-07 18:34:42.088437+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
172	justlend:USDD	0.00011961	2025-09-07 18:34:40.795+00	2025-09-07 18:34:42.088437+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
173	justlend:USDT	0.16633919	2025-09-07 18:34:40.795+00	2025-09-07 18:34:42.088437+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
174	stride:stATOM	0.12000000	2025-09-07 18:34:40.523+00	2025-09-07 18:34:42.088437+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
175	stride:stTIA	0.14000000	2025-09-07 18:34:40.523+00	2025-09-07 18:34:42.088437+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
176	aave:USDT	0.04239511	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
177	aave:USDC	0.02404591	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
178	aave:DAI	0.03576958	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
179	aave:AUSD	0.05223109	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
180	aave:USDT	0.03446297	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
181	aave:USDC	0.05528768	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
182	aave:USDC	0.04882521	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
183	aave:USDT	0.02838248	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
184	aave:DAI	0.03462488	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
185	aave:USDC	0.04882597	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
186	aave:USDC	0.00534778	2025-09-07 18:40:57.827+00	2025-09-07 18:40:59.881388+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
187	justlend:USDD	0.00014225	2025-09-07 18:40:58.137+00	2025-09-07 18:40:59.881388+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
188	justlend:USDT	0.16443306	2025-09-07 18:40:58.137+00	2025-09-07 18:40:59.881388+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
189	stride:stATOM	0.12000000	2025-09-07 18:40:57.829+00	2025-09-07 18:40:59.881388+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
190	stride:stTIA	0.14000000	2025-09-07 18:40:57.829+00	2025-09-07 18:40:59.881388+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
191	aave:USDT	0.04239511	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.10171+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
192	aave:USDC	0.02405256	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.128125+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
193	aave:DAI	0.03576958	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.130001+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
194	aave:USDT	0.03446297	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.131501+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
195	aave:USDC	0.05528768	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.133018+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
196	aave:USDC	0.04882521	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.134582+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
197	aave:USDT	0.02838248	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.136215+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
198	aave:DAI	0.03462488	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.137705+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
199	aave:USDC	0.04882597	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.141079+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
200	aave:USDC	0.00534778	2025-09-07 18:41:19.436+00	2025-09-07 18:41:21.145319+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
201	justlend:USDD	0.00014225	2025-09-07 18:41:19.717+00	2025-09-07 18:41:21.147495+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
202	justlend:USDT	0.16443306	2025-09-07 18:41:19.717+00	2025-09-07 18:41:21.149901+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
203	stride:stATOM	0.12000000	2025-09-07 18:41:19.44+00	2025-09-07 18:41:21.151261+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
204	stride:stTIA	0.14000000	2025-09-07 18:41:19.44+00	2025-09-07 18:41:21.152743+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
205	aave:USDT	0.04239515	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
206	aave:USDC	0.02405219	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
207	aave:DAI	0.03576958	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
208	aave:AUSD	0.05223109	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
209	aave:USDT	0.03446297	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
210	aave:USDC	0.05528768	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
211	aave:USDC	0.04882521	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
212	aave:USDT	0.02838248	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
213	aave:DAI	0.03462488	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
214	aave:USDC	0.04882597	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
215	aave:USDC	0.00534778	2025-09-07 18:44:01.408+00	2025-09-07 18:44:03.389186+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
216	justlend:USDD	0.00014225	2025-09-07 18:44:01.738+00	2025-09-07 18:44:03.389186+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
217	justlend:USDT	0.16443306	2025-09-07 18:44:01.738+00	2025-09-07 18:44:03.389186+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
218	stride:stATOM	0.12000000	2025-09-07 18:44:01.412+00	2025-09-07 18:44:03.389186+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
219	stride:stTIA	0.14000000	2025-09-07 18:44:01.412+00	2025-09-07 18:44:03.389186+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
220	aave:USDT	0.04239515	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
221	aave:USDC	0.02405219	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
222	aave:DAI	0.03576958	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
223	aave:AUSD	0.05223109	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
224	aave:USDT	0.03446297	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
225	aave:USDC	0.05528768	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
226	aave:USDC	0.04882521	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
227	aave:USDT	0.02838248	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
228	aave:DAI	0.03462488	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
229	aave:USDC	0.04882597	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
230	aave:USDC	0.00534778	2025-09-07 18:47:22.772+00	2025-09-07 18:47:24.567912+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
231	justlend:USDD	0.00014225	2025-09-07 18:47:23.044+00	2025-09-07 18:47:24.567912+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
232	justlend:USDT	0.16292216	2025-09-07 18:47:23.044+00	2025-09-07 18:47:24.567912+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
233	stride:stATOM	0.12000000	2025-09-07 18:47:22.792+00	2025-09-07 18:47:24.567912+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
234	stride:stTIA	0.14000000	2025-09-07 18:47:22.792+00	2025-09-07 18:47:24.567912+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
235	aave:USDT	0.04239514	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.236126+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
236	aave:USDC	0.02405219	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.249143+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
237	aave:DAI	0.03576958	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.251171+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
238	aave:USDT	0.03446297	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.25324+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
239	aave:USDC	0.05528768	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.255211+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
240	aave:USDC	0.04882521	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.25685+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
241	aave:USDT	0.02838248	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.2585+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
242	aave:DAI	0.03462488	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.260169+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
243	aave:USDC	0.04882597	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.261634+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
244	aave:USDC	0.00534778	2025-09-07 18:48:21.474+00	2025-09-07 18:48:23.263192+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
245	justlend:USDD	0.00014225	2025-09-07 18:48:21.747+00	2025-09-07 18:48:23.26961+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
246	justlend:USDT	0.16292216	2025-09-07 18:48:21.747+00	2025-09-07 18:48:23.271148+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
247	stride:stATOM	0.12000000	2025-09-07 18:48:21.476+00	2025-09-07 18:48:23.272743+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
248	stride:stTIA	0.14000000	2025-09-07 18:48:21.476+00	2025-09-07 18:48:23.274166+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
249	aave:USDT	0.04239514	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.187368+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
250	aave:USDC	0.02405219	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.194208+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
251	aave:DAI	0.03576958	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.195687+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
252	aave:USDT	0.03446297	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.196913+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
253	aave:USDC	0.05528768	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.198088+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
254	aave:USDC	0.04882521	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.199362+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
255	aave:USDT	0.02838248	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.200448+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
256	aave:DAI	0.03462488	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.201892+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
257	aave:USDC	0.04882597	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.203231+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
258	aave:USDC	0.00534778	2025-09-07 18:48:41.456+00	2025-09-07 18:48:43.204566+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
259	justlend:USDD	0.00014225	2025-09-07 18:48:41.746+00	2025-09-07 18:48:43.206461+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
260	justlend:USDT	0.16292216	2025-09-07 18:48:41.746+00	2025-09-07 18:48:43.207852+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
261	stride:stATOM	0.12000000	2025-09-07 18:48:41.458+00	2025-09-07 18:48:43.209449+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
262	stride:stTIA	0.14000000	2025-09-07 18:48:41.458+00	2025-09-07 18:48:43.210957+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
263	aave:USDT	0.04239514	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
264	aave:USDC	0.02405219	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
265	aave:DAI	0.03576958	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
266	aave:AUSD	0.05223109	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
267	aave:USDT	0.03446297	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
268	aave:USDC	0.05528768	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
269	aave:USDC	0.04882521	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
270	aave:USDT	0.02838248	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
271	aave:DAI	0.03462488	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
272	aave:USDC	0.04882597	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
273	aave:USDC	0.00534778	2025-09-07 18:50:20.551+00	2025-09-07 18:50:22.265476+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
274	justlend:USDD	0.00014225	2025-09-07 18:50:20.811+00	2025-09-07 18:50:22.265476+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
275	justlend:USDT	0.16292216	2025-09-07 18:50:20.811+00	2025-09-07 18:50:22.265476+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
276	stride:stATOM	0.12000000	2025-09-07 18:50:20.554+00	2025-09-07 18:50:22.265476+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
277	stride:stTIA	0.14000000	2025-09-07 18:50:20.554+00	2025-09-07 18:50:22.265476+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
278	aave:USDT	0.04239514	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
279	aave:USDC	0.02405219	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
280	aave:DAI	0.03576958	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
281	aave:AUSD	0.05223109	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
282	aave:USDT	0.03446297	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
283	aave:USDC	0.05528768	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
284	aave:USDC	0.04882521	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
285	aave:USDT	0.02838248	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
286	aave:DAI	0.03462488	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
287	aave:USDC	0.04882597	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
288	aave:USDC	0.00534778	2025-09-07 18:54:06.668+00	2025-09-07 18:54:08.598074+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
289	justlend:USDD	0.00014225	2025-09-07 18:54:06.896+00	2025-09-07 18:54:08.598074+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
290	justlend:USDT	0.16292216	2025-09-07 18:54:06.896+00	2025-09-07 18:54:08.598074+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
291	stride:stATOM	0.12000000	2025-09-07 18:54:06.689+00	2025-09-07 18:54:08.598074+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
292	stride:stTIA	0.14000000	2025-09-07 18:54:06.689+00	2025-09-07 18:54:08.598074+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
293	aave:USDT	0.04239514	2025-09-07 18:54:37.432+00	2025-09-07 18:54:38.948413+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
294	aave:USDC	0.02405219	2025-09-07 18:54:37.432+00	2025-09-07 18:54:38.95142+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
295	aave:DAI	0.03576958	2025-09-07 18:54:37.432+00	2025-09-07 18:54:38.997088+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
296	aave:USDT	0.03446297	2025-09-07 18:54:37.432+00	2025-09-07 18:54:38.998944+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
297	aave:USDC	0.05528768	2025-09-07 18:54:37.432+00	2025-09-07 18:54:39.000326+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
298	aave:USDC	0.04882521	2025-09-07 18:54:37.432+00	2025-09-07 18:54:39.001553+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
299	aave:USDT	0.02838248	2025-09-07 18:54:37.432+00	2025-09-07 18:54:39.003254+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
300	aave:DAI	0.03462488	2025-09-07 18:54:37.432+00	2025-09-07 18:54:39.004705+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
301	aave:USDC	0.04882597	2025-09-07 18:54:37.432+00	2025-09-07 18:54:39.006205+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
302	aave:USDC	0.00534778	2025-09-07 18:54:37.432+00	2025-09-07 18:54:39.007585+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
303	justlend:USDD	0.00014225	2025-09-07 18:54:37.689+00	2025-09-07 18:54:39.008922+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
304	justlend:USDT	0.16292216	2025-09-07 18:54:37.689+00	2025-09-07 18:54:39.010323+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
305	stride:stATOM	0.12000000	2025-09-07 18:54:37.434+00	2025-09-07 18:54:39.011721+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
306	stride:stTIA	0.14000000	2025-09-07 18:54:37.434+00	2025-09-07 18:54:39.013179+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
307	aave:USDT	0.04238922	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.324852+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
308	aave:USDC	0.02405219	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.333847+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
309	aave:DAI	0.03576958	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.425912+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
310	aave:USDT	0.04238922	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
311	aave:USDC	0.02405219	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
312	aave:DAI	0.03576958	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
313	aave:AUSD	0.05225834	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
314	aave:USDT	0.03446684	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
315	aave:USDC	0.05528768	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
316	aave:USDC	0.04891263	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
317	aave:USDT	0.02838141	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
318	aave:DAI	0.03462488	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
319	aave:USDC	0.04890825	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
320	aave:USDC	0.00516494	2025-09-07 19:44:57.505+00	2025-09-07 19:44:59.425649+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
321	justlend:USDD	0.00015588	2025-09-07 19:44:57.91+00	2025-09-07 19:44:59.425649+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
322	justlend:USDT	0.16131835	2025-09-07 19:44:57.91+00	2025-09-07 19:44:59.425649+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
323	stride:stATOM	0.12000000	2025-09-07 19:44:57.507+00	2025-09-07 19:44:59.425649+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
324	stride:stTIA	0.14000000	2025-09-07 19:44:57.507+00	2025-09-07 19:44:59.425649+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
325	aave:USDT	0.03446684	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.43616+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
326	aave:USDC	0.05528768	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.439873+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
327	aave:USDC	0.04891263	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.442073+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
328	aave:USDT	0.02838141	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.447668+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
329	aave:DAI	0.03462488	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.449486+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
330	aave:USDC	0.04890825	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.451042+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
331	aave:USDC	0.00516494	2025-09-07 19:44:57.515+00	2025-09-07 19:44:59.45252+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
332	justlend:USDD	0.00015588	2025-09-07 19:44:57.758+00	2025-09-07 19:44:59.454306+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
333	justlend:USDT	0.16131835	2025-09-07 19:44:57.758+00	2025-09-07 19:44:59.455828+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
334	stride:stATOM	0.12000000	2025-09-07 19:44:57.516+00	2025-09-07 19:44:59.457249+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
335	stride:stTIA	0.14000000	2025-09-07 19:44:57.516+00	2025-09-07 19:44:59.458789+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
336	aave:USDT	0.04238936	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.851491+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
337	aave:USDC	0.02405219	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.859945+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
338	aave:DAI	0.03576958	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.863115+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
339	aave:USDT	0.03446684	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.864913+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
340	aave:USDC	0.05528768	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.866593+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
341	aave:USDC	0.04891263	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.868476+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
342	aave:USDT	0.02838141	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.870756+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
343	aave:DAI	0.03462488	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.872439+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
344	aave:USDC	0.04890825	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.874234+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
345	aave:USDC	0.00516494	2025-09-07 19:47:39.208+00	2025-09-07 19:47:40.875821+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
346	justlend:USDD	0.00015588	2025-09-07 19:47:39.47+00	2025-09-07 19:47:40.877926+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
347	justlend:USDT	0.16013685	2025-09-07 19:47:39.47+00	2025-09-07 19:47:40.879959+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
348	stride:stATOM	0.12000000	2025-09-07 19:47:39.209+00	2025-09-07 19:47:40.882073+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
349	stride:stTIA	0.14000000	2025-09-07 19:47:39.209+00	2025-09-07 19:47:40.883905+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
350	aave:USDT	0.04238936	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
351	aave:USDC	0.02405219	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
352	aave:DAI	0.03576958	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
353	aave:AUSD	0.05225834	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
354	aave:USDT	0.03446684	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
355	aave:USDC	0.05528768	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
356	aave:USDC	0.04891263	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
357	aave:USDT	0.02838141	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
358	aave:DAI	0.03462488	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
359	aave:USDC	0.04890825	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
360	aave:USDC	0.00516494	2025-09-07 19:47:39.213+00	2025-09-07 19:47:41.097654+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
361	justlend:USDD	0.00015588	2025-09-07 19:47:39.463+00	2025-09-07 19:47:41.097654+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
362	justlend:USDT	0.16013685	2025-09-07 19:47:39.463+00	2025-09-07 19:47:41.097654+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
363	stride:stATOM	0.12000000	2025-09-07 19:47:39.215+00	2025-09-07 19:47:41.097654+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
364	stride:stTIA	0.14000000	2025-09-07 19:47:39.215+00	2025-09-07 19:47:41.097654+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
365	aave:USDT	0.04238970	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.843066+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
366	aave:USDC	0.02405219	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.851259+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
367	aave:DAI	0.03579239	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.931092+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
368	aave:USDT	0.03446684	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.932736+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
369	aave:USDC	0.05528768	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.934096+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
370	aave:USDC	0.04891263	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.935401+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
371	aave:USDT	0.02838141	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.936747+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
372	aave:DAI	0.03462488	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.938079+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
373	aave:USDC	0.04890825	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.939445+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
374	aave:USDC	0.00516494	2025-09-07 19:53:45.286+00	2025-09-07 19:53:46.941619+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
375	justlend:USDD	0.00015595	2025-09-07 19:53:45.62+00	2025-09-07 19:53:46.943175+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
376	justlend:USDT	0.15725592	2025-09-07 19:53:45.62+00	2025-09-07 19:53:46.945301+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
377	stride:stATOM	0.12000000	2025-09-07 19:53:45.309+00	2025-09-07 19:53:46.946779+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
378	stride:stTIA	0.14000000	2025-09-07 19:53:45.309+00	2025-09-07 19:53:46.948276+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
379	aave:USDT	0.04238970	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
380	aave:USDC	0.02405219	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
381	aave:DAI	0.03579239	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
382	aave:AUSD	0.05225834	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
383	aave:USDT	0.03446684	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
384	aave:USDC	0.05528768	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
385	aave:USDC	0.04891263	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
386	aave:USDT	0.02838141	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
387	aave:DAI	0.03462488	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
388	aave:USDC	0.04890825	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
389	aave:USDC	0.00516494	2025-09-07 19:53:45.315+00	2025-09-07 19:53:47.217743+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
390	justlend:USDD	0.00015595	2025-09-07 19:53:45.62+00	2025-09-07 19:53:47.217743+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
391	justlend:USDT	0.15725592	2025-09-07 19:53:45.62+00	2025-09-07 19:53:47.217743+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
392	stride:stATOM	0.12000000	2025-09-07 19:53:45.317+00	2025-09-07 19:53:47.217743+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
393	stride:stTIA	0.14000000	2025-09-07 19:53:45.317+00	2025-09-07 19:53:47.217743+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
394	aave:USDT	0.04239136	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.035495+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
395	aave:USDC	0.02405219	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.041867+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
396	aave:DAI	0.03579239	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.044404+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
397	aave:USDT	0.03446684	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.04735+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
398	aave:USDC	0.05528768	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.049991+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
399	aave:USDC	0.04891263	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.051817+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
400	aave:USDT	0.02838141	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.053418+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
401	aave:DAI	0.03462488	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.055184+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
402	aave:USDC	0.04890825	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.056704+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
403	aave:USDC	0.00516494	2025-09-07 19:54:47.372+00	2025-09-07 19:54:49.058236+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
404	justlend:USDD	0.00015595	2025-09-07 19:54:47.748+00	2025-09-07 19:54:49.059942+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
405	justlend:USDT	0.15725232	2025-09-07 19:54:47.748+00	2025-09-07 19:54:49.061298+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
406	stride:stATOM	0.12000000	2025-09-07 19:54:47.375+00	2025-09-07 19:54:49.062629+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
407	stride:stTIA	0.14000000	2025-09-07 19:54:47.375+00	2025-09-07 19:54:49.063951+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
408	aave:USDT	0.04239136	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
409	aave:USDC	0.02405219	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
410	aave:DAI	0.03579239	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
411	aave:AUSD	0.05225834	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
412	aave:USDT	0.03446684	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
413	aave:USDC	0.05528768	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
414	aave:USDC	0.04891263	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
415	aave:USDT	0.02838141	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
416	aave:DAI	0.03462488	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
417	aave:USDC	0.04890825	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
418	aave:USDC	0.00516494	2025-09-07 19:54:47.378+00	2025-09-07 19:54:49.583507+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
419	justlend:USDD	0.00015595	2025-09-07 19:54:47.697+00	2025-09-07 19:54:49.583507+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
420	justlend:USDT	0.15725232	2025-09-07 19:54:47.697+00	2025-09-07 19:54:49.583507+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
421	stride:stATOM	0.12000000	2025-09-07 19:54:47.379+00	2025-09-07 19:54:49.583507+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
422	stride:stTIA	0.14000000	2025-09-07 19:54:47.379+00	2025-09-07 19:54:49.583507+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
423	aave:USDT	0.04237563	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
424	aave:USDC	0.02405219	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
425	aave:DAI	0.03579239	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
426	aave:AUSD	0.05235711	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
427	aave:USDT	0.03446684	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
428	aave:USDC	0.05528768	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
429	aave:USDC	0.04891263	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
430	aave:USDT	0.02838141	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
431	aave:DAI	0.03462488	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
432	aave:USDC	0.04890825	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
433	aave:USDC	0.00516494	2025-09-07 20:17:25.926+00	2025-09-07 20:17:27.778608+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
434	justlend:USDD	0.00015669	2025-09-07 20:17:26.203+00	2025-09-07 20:17:27.778608+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
435	justlend:USDT	0.12421711	2025-09-07 20:17:26.203+00	2025-09-07 20:17:27.778608+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
436	stride:stATOM	0.12000000	2025-09-07 20:17:25.947+00	2025-09-07 20:17:27.778608+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
437	stride:stTIA	0.14000000	2025-09-07 20:17:25.947+00	2025-09-07 20:17:27.778608+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
438	aave:USDT	0.04237563	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
439	aave:USDC	0.02405219	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
440	aave:DAI	0.03579239	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
441	aave:AUSD	0.05235711	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
442	aave:USDT	0.03446684	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
443	aave:USDC	0.05528768	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
444	aave:USDC	0.04891263	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
445	aave:USDT	0.02838141	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
446	aave:DAI	0.03462488	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
447	aave:USDC	0.04890825	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
448	aave:USDC	0.00516494	2025-09-07 20:20:33.84+00	2025-09-07 20:20:35.560444+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
449	justlend:USDD	0.00015669	2025-09-07 20:20:34.069+00	2025-09-07 20:20:35.560444+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
450	justlend:USDT	0.12421711	2025-09-07 20:20:34.069+00	2025-09-07 20:20:35.560444+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
451	stride:stATOM	0.12000000	2025-09-07 20:20:33.842+00	2025-09-07 20:20:35.560444+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
452	stride:stTIA	0.14000000	2025-09-07 20:20:33.842+00	2025-09-07 20:20:35.560444+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
453	aave:USDT	0.04237575	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
454	aave:USDC	0.02405219	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
455	aave:DAI	0.03579239	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
456	aave:AUSD	0.05235711	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
457	aave:USDT	0.03446684	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
458	aave:USDC	0.05528768	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
459	aave:USDC	0.04891263	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
460	aave:USDT	0.02838141	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
461	aave:DAI	0.03462488	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
462	aave:USDC	0.04890825	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
463	aave:USDC	0.00516494	2025-09-07 20:21:48.762+00	2025-09-07 20:21:50.390069+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
464	justlend:USDD	0.00015673	2025-09-07 20:21:48.965+00	2025-09-07 20:21:50.390069+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
465	justlend:USDT	0.12421711	2025-09-07 20:21:48.965+00	2025-09-07 20:21:50.390069+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
466	stride:stATOM	0.12000000	2025-09-07 20:21:48.763+00	2025-09-07 20:21:50.390069+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
467	stride:stTIA	0.14000000	2025-09-07 20:21:48.763+00	2025-09-07 20:21:50.390069+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
468	aave:USDT	0.04237634	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
469	aave:USDC	0.02405219	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
470	aave:DAI	0.03579239	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
471	aave:AUSD	0.05235711	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
472	aave:USDT	0.03450123	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
473	aave:USDC	0.05528768	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
474	aave:USDC	0.04894948	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
475	aave:USDT	0.02837704	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
476	aave:DAI	0.03462488	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
477	aave:USDC	0.04902623	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
478	aave:USDC	0.00516494	2025-09-07 20:23:03.073+00	2025-09-07 20:23:04.723726+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
479	justlend:USDD	0.00015677	2025-09-07 20:23:03.877+00	2025-09-07 20:23:04.723726+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
480	justlend:USDT	0.12250664	2025-09-07 20:23:03.877+00	2025-09-07 20:23:04.723726+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
481	stride:stATOM	0.12000000	2025-09-07 20:23:03.075+00	2025-09-07 20:23:04.723726+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
482	stride:stTIA	0.14000000	2025-09-07 20:23:03.075+00	2025-09-07 20:23:04.723726+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
483	aave:USDT	0.04237634	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
484	aave:USDC	0.02405219	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
485	aave:DAI	0.03579239	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
486	aave:AUSD	0.05235711	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
487	aave:USDT	0.03450123	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
488	aave:USDC	0.05528768	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
489	aave:USDC	0.04894948	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
490	aave:USDT	0.02837704	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
491	aave:DAI	0.03462488	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
492	aave:USDC	0.04902623	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
493	aave:USDC	0.00516494	2025-09-07 20:24:09.795+00	2025-09-07 20:24:11.160128+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
494	justlend:USDD	0.00015677	2025-09-07 20:24:10.004+00	2025-09-07 20:24:11.160128+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
495	justlend:USDT	0.12088875	2025-09-07 20:24:10.004+00	2025-09-07 20:24:11.160128+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
496	stride:stATOM	0.12000000	2025-09-07 20:24:09.796+00	2025-09-07 20:24:11.160128+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
497	stride:stTIA	0.14000000	2025-09-07 20:24:09.796+00	2025-09-07 20:24:11.160128+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
498	aave:USDT	0.04237634	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
499	aave:USDC	0.02405219	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
500	aave:DAI	0.03579239	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
501	aave:AUSD	0.05235701	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
502	aave:USDT	0.03450123	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
503	aave:USDC	0.05528768	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
504	aave:USDC	0.04894948	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
505	aave:USDT	0.02837704	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
506	aave:DAI	0.03462488	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
507	aave:USDC	0.04902623	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
508	aave:USDC	0.00516494	2025-09-07 20:26:33.279+00	2025-09-07 20:26:34.971578+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
509	justlend:USDD	0.00015681	2025-09-07 20:26:33.492+00	2025-09-07 20:26:34.971578+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
510	justlend:USDT	0.11928385	2025-09-07 20:26:33.492+00	2025-09-07 20:26:34.971578+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
511	stride:stATOM	0.12000000	2025-09-07 20:26:33.28+00	2025-09-07 20:26:34.971578+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
512	stride:stTIA	0.14000000	2025-09-07 20:26:33.28+00	2025-09-07 20:26:34.971578+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
513	aave:USDT	0.04237635	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.053741+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
514	aave:USDC	0.02405219	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.064707+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
515	aave:DAI	0.03579239	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.067107+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
516	aave:USDT	0.03450123	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.069075+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
517	aave:USDC	0.05528768	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.071378+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
518	aave:USDC	0.04894948	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.138931+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
519	aave:USDT	0.02837704	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.218811+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
520	aave:DAI	0.03462488	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.221285+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
521	aave:USDC	0.04902623	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.223343+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
522	aave:USDC	0.00516494	2025-09-07 20:36:33.457+00	2025-09-07 20:36:35.225181+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
523	justlend:USDD	0.00015681	2025-09-07 20:36:33.708+00	2025-09-07 20:36:35.227024+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
524	justlend:USDT	0.11928385	2025-09-07 20:36:33.708+00	2025-09-07 20:36:35.230235+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
525	stride:stATOM	0.12000000	2025-09-07 20:36:33.458+00	2025-09-07 20:36:35.232513+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
526	stride:stTIA	0.14000000	2025-09-07 20:36:33.458+00	2025-09-07 20:36:35.235346+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
527	aave:USDT	0.04237635	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
528	aave:USDC	0.02405219	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
529	aave:DAI	0.03579239	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
530	aave:AUSD	0.05235190	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
531	aave:USDT	0.03450123	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
532	aave:USDC	0.05528768	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
533	aave:USDC	0.04894948	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
534	aave:USDT	0.02837704	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
535	aave:DAI	0.03462488	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
536	aave:USDC	0.04902623	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
537	aave:USDC	0.00516494	2025-09-07 20:36:33.425+00	2025-09-07 20:36:35.450067+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
538	justlend:USDD	0.00015681	2025-09-07 20:36:33.646+00	2025-09-07 20:36:35.450067+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
539	justlend:USDT	0.11928385	2025-09-07 20:36:33.646+00	2025-09-07 20:36:35.450067+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
540	stride:stATOM	0.12000000	2025-09-07 20:36:33.447+00	2025-09-07 20:36:35.450067+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
541	stride:stTIA	0.14000000	2025-09-07 20:36:33.447+00	2025-09-07 20:36:35.450067+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
542	aave:USDT	0.04237590	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.847817+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
543	aave:USDC	0.02405219	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.856052+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
544	aave:DAI	0.03579239	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.858314+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
545	aave:USDT	0.03450123	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.860162+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
546	aave:USDC	0.05528768	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.862757+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
547	aave:USDC	0.04894948	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.865415+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
548	aave:USDT	0.02837704	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.867696+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
549	aave:DAI	0.03462488	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.870103+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
550	aave:USDC	0.04902623	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.873621+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
551	aave:USDC	0.00516494	2025-09-07 20:49:24.328+00	2025-09-07 20:49:25.875327+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
552	justlend:USDD	0.00015681	2025-09-07 20:49:24.615+00	2025-09-07 20:49:25.877092+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
553	justlend:USDT	0.11928385	2025-09-07 20:49:24.615+00	2025-09-07 20:49:25.879905+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
554	stride:stATOM	0.12000000	2025-09-07 20:49:24.33+00	2025-09-07 20:49:25.881656+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
555	stride:stTIA	0.14000000	2025-09-07 20:49:24.33+00	2025-09-07 20:49:25.883423+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
556	aave:USDT	0.04237590	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
557	aave:USDC	0.02405219	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
558	aave:DAI	0.03579239	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
559	aave:AUSD	0.05235190	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
560	aave:USDT	0.03450123	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
561	aave:USDC	0.05528768	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
562	aave:USDC	0.04894948	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
563	aave:USDT	0.02837704	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
564	aave:DAI	0.03462488	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
565	aave:USDC	0.04902623	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
566	aave:USDC	0.00516494	2025-09-07 20:49:24.324+00	2025-09-07 20:49:26.144653+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
567	justlend:USDD	0.00015681	2025-09-07 20:49:24.607+00	2025-09-07 20:49:26.144653+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
568	justlend:USDT	0.11928385	2025-09-07 20:49:24.607+00	2025-09-07 20:49:26.144653+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
569	stride:stATOM	0.12000000	2025-09-07 20:49:24.326+00	2025-09-07 20:49:26.144653+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
570	stride:stTIA	0.14000000	2025-09-07 20:49:24.326+00	2025-09-07 20:49:26.144653+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
571	aave:USDT	0.04237590	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.38228+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
572	aave:USDC	0.02405219	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.384919+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
573	aave:DAI	0.03579239	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.388822+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
574	aave:USDT	0.03450123	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.390489+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
575	aave:USDC	0.05528768	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.391899+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
576	aave:USDC	0.04894948	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.39331+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
577	aave:USDT	0.02837704	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.394654+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
578	aave:DAI	0.03462488	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.395996+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
579	aave:USDC	0.04902623	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.397366+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
580	aave:USDC	0.00516494	2025-09-07 20:50:07.699+00	2025-09-07 20:50:09.398621+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
581	justlend:USDD	0.00015681	2025-09-07 20:50:07.928+00	2025-09-07 20:50:09.399975+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
582	justlend:USDT	0.11928385	2025-09-07 20:50:07.928+00	2025-09-07 20:50:09.401292+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
583	stride:stATOM	0.12000000	2025-09-07 20:50:07.701+00	2025-09-07 20:50:09.402601+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
584	stride:stTIA	0.14000000	2025-09-07 20:50:07.701+00	2025-09-07 20:50:09.404761+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
585	aave:USDT	0.04237206	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.01387+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
586	aave:USDC	0.02405219	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.062266+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
587	aave:DAI	0.03579239	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.064129+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
588	aave:USDT	0.03450123	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.065619+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
589	aave:USDC	0.05528768	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.066933+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
590	aave:USDC	0.04894948	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.068405+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
591	aave:USDT	0.02837704	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.070166+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
592	aave:DAI	0.03462488	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.071659+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
593	aave:USDC	0.04902623	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.073167+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
594	aave:USDC	0.00516494	2025-09-07 20:59:01.497+00	2025-09-07 20:59:03.074679+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
595	justlend:USDD	0.00015681	2025-09-07 20:59:01.81+00	2025-09-07 20:59:03.07686+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
596	justlend:USDT	0.11928385	2025-09-07 20:59:01.81+00	2025-09-07 20:59:03.078535+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
597	stride:stATOM	0.12000000	2025-09-07 20:59:01.519+00	2025-09-07 20:59:03.079946+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
598	stride:stTIA	0.14000000	2025-09-07 20:59:01.519+00	2025-09-07 20:59:03.081407+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
599	aave:USDT	0.04237206	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
600	aave:USDC	0.02405219	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
601	aave:DAI	0.03579239	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
602	aave:AUSD	0.05235190	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
603	aave:USDT	0.03450123	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
604	aave:USDC	0.05528768	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
605	aave:USDC	0.04894948	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
606	aave:USDT	0.02837704	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
607	aave:DAI	0.03462488	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
608	aave:USDC	0.04902623	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
609	aave:USDC	0.00516494	2025-09-07 20:59:01.524+00	2025-09-07 20:59:03.393524+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
610	justlend:USDD	0.00015681	2025-09-07 20:59:01.821+00	2025-09-07 20:59:03.393524+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
611	justlend:USDT	0.11928385	2025-09-07 20:59:01.821+00	2025-09-07 20:59:03.393524+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
612	stride:stATOM	0.12000000	2025-09-07 20:59:01.526+00	2025-09-07 20:59:03.393524+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
613	stride:stTIA	0.14000000	2025-09-07 20:59:01.526+00	2025-09-07 20:59:03.393524+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
614	aave:USDT	0.04244455	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
615	aave:USDC	0.02405281	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
616	aave:DAI	0.03575582	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
617	aave:AUSD	0.05186056	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
618	aave:USDT	0.03724511	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
619	aave:USDC	0.05528768	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
620	aave:USDC	0.04902576	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
621	aave:USDT	0.02844644	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
622	aave:DAI	0.03463831	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
623	aave:USDC	0.04899195	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
624	aave:USDC	0.00516494	2025-09-07 23:19:10.708+00	2025-09-07 23:19:13.306702+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
625	justlend:USDD	0.00015681	2025-09-07 23:19:10.938+00	2025-09-07 23:19:13.306702+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
626	justlend:USDT	0.14555466	2025-09-07 23:19:10.938+00	2025-09-07 23:19:13.306702+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
627	stride:stATOM	0.12000000	2025-09-07 23:19:10.716+00	2025-09-07 23:19:13.306702+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
628	stride:stTIA	0.14000000	2025-09-07 23:19:10.716+00	2025-09-07 23:19:13.306702+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
629	aave:USDT	0.04245628	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
630	aave:USDC	0.02405281	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
631	aave:DAI	0.03575620	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
632	aave:AUSD	0.05225486	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
633	aave:USDT	0.03724511	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
634	aave:USDC	0.05528768	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
635	aave:USDC	0.04902576	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
636	aave:USDT	0.02844644	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
637	aave:DAI	0.03463831	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
638	aave:USDC	0.04899195	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
639	aave:USDC	0.00516494	2025-09-07 23:20:52.073+00	2025-09-07 23:20:54.470174+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
640	justlend:USDD	0.00015681	2025-09-07 23:20:53.191+00	2025-09-07 23:20:54.470174+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
641	justlend:USDT	0.16553134	2025-09-07 23:20:53.191+00	2025-09-07 23:20:54.470174+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
642	stride:stATOM	0.12000000	2025-09-07 23:20:52.076+00	2025-09-07 23:20:54.470174+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
643	stride:stTIA	0.14000000	2025-09-07 23:20:52.076+00	2025-09-07 23:20:54.470174+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
644	aave:USDT	0.04245628	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
645	aave:USDC	0.02405281	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
646	aave:DAI	0.03575620	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
647	aave:AUSD	0.05225486	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	AUSD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
648	aave:USDT	0.03724511	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
649	aave:USDC	0.05528768	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
650	aave:USDC	0.04902576	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
651	aave:USDT	0.02844644	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
652	aave:DAI	0.03463831	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	DAI	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
653	aave:USDC	0.04899195	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
654	aave:USDC	0.00516494	2025-09-07 23:21:59.54+00	2025-09-07 23:22:01.571334+00	aave	\N	USDC	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
655	justlend:USDD	0.00015729	2025-09-07 23:21:59.751+00	2025-09-07 23:22:01.571334+00	justlend	\N	USDD	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
656	justlend:USDT	0.18611434	2025-09-07 23:21:59.751+00	2025-09-07 23:22:01.571334+00	justlend	\N	USDT	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
657	stride:stATOM	0.12000000	2025-09-07 23:21:59.541+00	2025-09-07 23:22:01.571334+00	stride	\N	stATOM	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
658	stride:stTIA	0.14000000	2025-09-07 23:21:59.541+00	2025-09-07 23:22:01.571334+00	stride	\N	stTIA	\N	\N	\N	\N	2025-09-07 23:28:14.586915+00
1022	aave:AUSD	0.05159491	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	avalanche	AUSD	0.05294527636181434	\N	\N	onchain	2025-09-10 02:04:45.060929+00
896	aave:AUSD	0.05174753	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	avalanche	AUSD	0.05310596902636555	\N	\N	onchain	2025-09-10 01:55:55.052757+00
900	aave:DAI	0.03471461	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 01:55:55.066469+00
893	aave:USDT	0.04434195	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:55:55.068955+00
897	aave:USDT	0.04198199	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:55:55.068955+00
901	aave:USDT	0.03161591	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 01:55:55.068955+00
898	aave:USDC	0.04559707	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:55:55.073365+00
899	aave:USDC	0.04983562	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:55:55.073365+00
902	aave:USDC	0.06175405	2025-09-10 01:55:53.08+00	2025-09-10 01:55:55.04154+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 01:55:55.073365+00
904	justlend:USDD	0.00001436	2025-09-10 01:55:53.347+00	2025-09-10 01:55:55.04154+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 01:55:55.076924+00
905	justlend:USDT	0.01458957	2025-09-10 01:55:53.347+00	2025-09-10 01:55:55.04154+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 01:55:55.080112+00
906	stride:stATOM	0.15140000	2025-09-10 01:55:53.098+00	2025-09-10 01:55:55.04154+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 01:55:55.082781+00
907	stride:stTIA	0.11000000	2025-09-10 01:55:53.098+00	2025-09-10 01:55:55.04154+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 01:55:55.084535+00
908	stride:stJUNO	0.22620000	2025-09-10 01:55:53.098+00	2025-09-10 01:55:55.04154+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 01:55:55.086335+00
909	stride:stLUNA	0.17720000	2025-09-10 01:55:53.098+00	2025-09-10 01:55:55.04154+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 01:55:55.08786+00
910	stride:stBAND	0.15430000	2025-09-10 01:55:53.098+00	2025-09-10 01:55:55.04154+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 01:55:55.089976+00
1020	aave:USDC	0.02116666	2025-09-10 02:04:40.004+00	2025-09-10 02:04:45.0411+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:04:45.166757+00
1031	justlend:USDT	0.01458957	2025-09-10 02:04:40.416+00	2025-09-10 02:04:45.0411+00	justlend	tron	USDT	0.014696219750738981	\N	0	justlend	2025-09-10 02:04:45.184707+00
1034	stride:stJUNO	0.22620000	2025-09-10 02:04:40.005+00	2025-09-10 02:04:45.0411+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 02:04:45.200767+00
1163	aave:USDT	0.04393592	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:57.930713+00
1174	justlend:USDD	0.00001452	2025-09-10 16:58:56.251+00	2025-09-10 16:58:57.846202+00	justlend	tron	USDD	1.4518438567145964e-05	\N	0	justlend	2025-09-10 16:58:57.945528+00
1175	justlend:USDT	0.01457255	2025-09-10 16:58:56.251+00	2025-09-10 16:58:57.846202+00	justlend	tron	USDT	0.014678948569817774	\N	0	justlend	2025-09-10 16:58:57.951561+00
1176	stride:stATOM	0.15140000	2025-09-10 16:58:56.021+00	2025-09-10 16:58:57.846202+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 16:58:57.958067+00
1055	aave:USDT	0.04291724	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.675761+00
1059	aave:USDT	0.04198199	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.675761+00
1063	aave:USDT	0.03161591	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.675761+00
1177	stride:stTIA	0.11000000	2025-09-10 16:58:56.021+00	2025-09-10 16:58:57.846202+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 16:58:57.963145+00
1178	stride:stJUNO	0.22620000	2025-09-10 16:58:56.021+00	2025-09-10 16:58:57.846202+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 16:58:57.968507+00
1179	stride:stLUNA	0.17720000	2025-09-10 16:58:56.021+00	2025-09-10 16:58:57.846202+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 16:58:57.975547+00
1180	stride:stBAND	0.15430000	2025-09-10 16:58:56.021+00	2025-09-10 16:58:57.846202+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 16:58:57.980916+00
1060	aave:USDC	0.04559707	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.680217+00
1061	aave:USDC	0.04983562	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.680217+00
1064	aave:USDC	0.06175405	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.680217+00
1065	aave:USDC	0.02546275	2025-09-10 02:21:15.988+00	2025-09-10 02:21:17.542773+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.680217+00
1066	justlend:USDD	0.00001436	2025-09-10 02:21:16.261+00	2025-09-10 02:21:17.542773+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 02:21:17.682289+00
1067	justlend:USDT	0.01471227	2025-09-10 02:21:16.261+00	2025-09-10 02:21:17.542773+00	justlend	tron	USDT	0.01482072921859201	\N	0	justlend	2025-09-10 02:21:17.684496+00
1069	stride:stTIA	0.11000000	2025-09-10 02:21:15.991+00	2025-09-10 02:21:17.542773+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 02:21:17.688523+00
1072	stride:stBAND	0.15430000	2025-09-10 02:21:15.991+00	2025-09-10 02:21:17.542773+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 02:21:17.694547+00
1112	aave:AUSD	0.05157484	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	avalanche	AUSD	0.052924147902371876	\N	\N	onchain	2025-09-10 04:55:42.66641+00
1111	aave:DAI	0.03639510	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	ethereum	DAI	0.035351400000000005	\N	\N	llama	2025-09-10 04:55:42.676851+00
1116	aave:DAI	0.03474089	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	ethereum	DAI	0.035351400000000005	\N	\N	llama	2025-09-10 04:55:42.676851+00
1109	aave:USDT	0.04314757	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.679033+00
1113	aave:USDT	0.04200012	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.679033+00
1117	aave:USDT	0.03206876	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.679033+00
1110	aave:USDC	0.02117012	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.683693+00
1114	aave:USDC	0.04550114	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.683693+00
1115	aave:USDC	0.04943044	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.683693+00
1118	aave:USDC	0.05145214	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.683693+00
1119	aave:USDC	0.02546275	2025-09-10 04:55:41.197+00	2025-09-10 04:55:42.649889+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.683693+00
1120	justlend:USDD	0.00001446	2025-09-10 04:55:41.436+00	2025-09-10 04:55:42.649889+00	justlend	tron	USDD	1.4463270782139048e-05	\N	0	justlend	2025-09-10 04:55:42.688094+00
1121	justlend:USDT	0.01460528	2025-09-10 04:55:41.436+00	2025-09-10 04:55:42.649889+00	justlend	tron	USDT	0.01471216595588798	\N	0	justlend	2025-09-10 04:55:42.692695+00
1122	stride:stATOM	0.15140000	2025-09-10 04:55:41.199+00	2025-09-10 04:55:42.649889+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 04:55:42.696691+00
1123	stride:stTIA	0.11000000	2025-09-10 04:55:41.199+00	2025-09-10 04:55:42.649889+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 04:55:42.702001+00
1124	stride:stJUNO	0.22620000	2025-09-10 04:55:41.199+00	2025-09-10 04:55:42.649889+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 04:55:42.705402+00
1125	stride:stLUNA	0.17720000	2025-09-10 04:55:41.199+00	2025-09-10 04:55:42.649889+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 04:55:42.708058+00
1126	stride:stBAND	0.15430000	2025-09-10 04:55:41.199+00	2025-09-10 04:55:42.649889+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 04:55:42.710199+00
1130	aave:AUSD	0.05157484	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	avalanche	AUSD	0.052924147902371876	\N	\N	onchain	2025-09-10 04:55:42.9427+00
1129	aave:DAI	0.03639510	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	ethereum	DAI	0.035351400000000005	\N	\N	llama	2025-09-10 04:55:42.955213+00
1134	aave:DAI	0.03474089	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	ethereum	DAI	0.035351400000000005	\N	\N	llama	2025-09-10 04:55:42.955213+00
1127	aave:USDT	0.04314757	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.957689+00
1131	aave:USDT	0.04200012	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.957689+00
1135	aave:USDT	0.03206876	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.957689+00
1128	aave:USDC	0.02117012	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.963275+00
1132	aave:USDC	0.04550114	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.963275+00
1133	aave:USDC	0.04943044	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.963275+00
1136	aave:USDC	0.05145214	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.963275+00
1137	aave:USDC	0.02546275	2025-09-10 04:55:41.212+00	2025-09-10 04:55:42.837425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.963275+00
1138	justlend:USDD	0.00001446	2025-09-10 04:55:41.514+00	2025-09-10 04:55:42.837425+00	justlend	tron	USDD	1.4463270782139048e-05	\N	0	justlend	2025-09-10 04:55:42.966331+00
1139	justlend:USDT	0.01460528	2025-09-10 04:55:41.514+00	2025-09-10 04:55:42.837425+00	justlend	tron	USDT	0.01471216595588798	\N	0	justlend	2025-09-10 04:55:42.969311+00
1140	stride:stATOM	0.15140000	2025-09-10 04:55:41.214+00	2025-09-10 04:55:42.837425+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 04:55:42.971606+00
1141	stride:stTIA	0.11000000	2025-09-10 04:55:41.214+00	2025-09-10 04:55:42.837425+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 04:55:42.9751+00
1142	stride:stJUNO	0.22620000	2025-09-10 04:55:41.214+00	2025-09-10 04:55:42.837425+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 04:55:42.978005+00
1143	stride:stLUNA	0.17720000	2025-09-10 04:55:41.214+00	2025-09-10 04:55:42.837425+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 04:55:42.980947+00
1144	stride:stBAND	0.15430000	2025-09-10 04:55:41.214+00	2025-09-10 04:55:42.837425+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 04:55:42.984585+00
1045	aave:USDT	0.03161591	2025-09-10 02:04:39.997+00	2025-09-10 02:04:45.127626+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:04:45.199246+00
1300	justlend:USDD	0.00001463	2025-09-11 00:49:42.103+00	2025-09-11 00:49:43.988066+00	justlend	tron	USDD	1.4632968433181404e-05	\N	0	justlend	2025-09-11 00:49:44.06439+00
1302	stride:stATOM	0.15140000	2025-09-11 00:49:41.8+00	2025-09-11 00:49:43.988066+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-11 00:49:44.07516+00
1076	aave:AUSD	0.05158318	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	avalanche	AUSD	0.05293292587335818	\N	\N	onchain	2025-09-10 02:21:17.672581+00
1075	aave:DAI	0.03626048	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:21:17.681219+00
1080	aave:DAI	0.03471461	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:21:17.681219+00
1073	aave:USDT	0.04291724	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.683423+00
1077	aave:USDT	0.04198199	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.683423+00
1081	aave:USDT	0.03161591	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.683423+00
1074	aave:USDC	0.02116666	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.68761+00
1078	aave:USDC	0.04559707	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.68761+00
1079	aave:USDC	0.04983562	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.68761+00
1082	aave:USDC	0.06175405	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.68761+00
1083	aave:USDC	0.02546275	2025-09-10 02:21:16+00	2025-09-10 02:21:17.657516+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.68761+00
1084	justlend:USDD	0.00001436	2025-09-10 02:21:16.283+00	2025-09-10 02:21:17.657516+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 02:21:17.68955+00
1085	justlend:USDT	0.01471227	2025-09-10 02:21:16.283+00	2025-09-10 02:21:17.657516+00	justlend	tron	USDT	0.01482072921859201	\N	0	justlend	2025-09-10 02:21:17.691573+00
1086	stride:stATOM	0.15140000	2025-09-10 02:21:16.001+00	2025-09-10 02:21:17.657516+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 02:21:17.693516+00
1087	stride:stTIA	0.11000000	2025-09-10 02:21:16.001+00	2025-09-10 02:21:17.657516+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 02:21:17.695595+00
1088	stride:stJUNO	0.22620000	2025-09-10 02:21:16.001+00	2025-09-10 02:21:17.657516+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 02:21:17.697806+00
1089	stride:stLUNA	0.17720000	2025-09-10 02:21:16.001+00	2025-09-10 02:21:17.657516+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 02:21:17.699372+00
1090	stride:stBAND	0.15430000	2025-09-10 02:21:16.001+00	2025-09-10 02:21:17.657516+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 02:21:17.700995+00
1094	aave:AUSD	0.05158318	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	avalanche	AUSD	0.05293292587335818	\N	\N	onchain	2025-09-10 02:21:17.771469+00
1093	aave:DAI	0.03626048	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:21:17.78352+00
1098	aave:DAI	0.03471461	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	ethereum	DAI	0.0353242	\N	\N	llama	2025-09-10 02:21:17.78352+00
1091	aave:USDT	0.04291724	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.785818+00
1095	aave:USDT	0.04198199	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.785818+00
1099	aave:USDT	0.03161591	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	avalanche	USDT	0.032121	\N	\N	llama	2025-09-10 02:21:17.785818+00
1092	aave:USDC	0.02116666	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.789038+00
1096	aave:USDC	0.04559707	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.789038+00
1097	aave:USDC	0.04983562	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.789038+00
1100	aave:USDC	0.06175405	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.789038+00
1101	aave:USDC	0.02546275	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 02:21:17.789038+00
1102	justlend:USDD	0.00001436	2025-09-10 02:21:16.253+00	2025-09-10 02:21:17.760425+00	justlend	tron	USDD	1.435906378599583e-05	\N	0	justlend	2025-09-10 02:21:17.790601+00
1103	justlend:USDT	0.01471227	2025-09-10 02:21:16.253+00	2025-09-10 02:21:17.760425+00	justlend	tron	USDT	0.01482072921859201	\N	0	justlend	2025-09-10 02:21:17.792001+00
1104	stride:stATOM	0.15140000	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 02:21:17.793394+00
1105	stride:stTIA	0.11000000	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 02:21:17.795202+00
1106	stride:stJUNO	0.22620000	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 02:21:17.796935+00
1107	stride:stLUNA	0.17720000	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 02:21:17.798728+00
1108	stride:stBAND	0.15430000	2025-09-10 02:21:15.992+00	2025-09-10 02:21:17.760425+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 02:21:17.800442+00
1148	aave:AUSD	0.05157484	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	avalanche	AUSD	0.052924147902371876	\N	\N	onchain	2025-09-10 04:55:42.95338+00
1147	aave:DAI	0.03639510	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	ethereum	DAI	0.035351400000000005	\N	\N	llama	2025-09-10 04:55:42.964493+00
1152	aave:DAI	0.03474089	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	ethereum	DAI	0.035351400000000005	\N	\N	llama	2025-09-10 04:55:42.964493+00
1145	aave:USDT	0.04314757	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.967667+00
1149	aave:USDT	0.04200012	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.967667+00
1153	aave:USDT	0.03206876	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	avalanche	USDT	0.0325885	\N	\N	llama	2025-09-10 04:55:42.967667+00
1146	aave:USDC	0.02117012	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.973104+00
1150	aave:USDC	0.04550114	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.973104+00
1151	aave:USDC	0.04943044	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.973104+00
1154	aave:USDC	0.05145214	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.973104+00
1155	aave:USDC	0.02546275	2025-09-10 04:55:41.201+00	2025-09-10 04:55:42.941443+00	aave	celo	USDC	0.0257897	\N	\N	llama	2025-09-10 04:55:42.973104+00
1156	justlend:USDD	0.00001446	2025-09-10 04:55:41.444+00	2025-09-10 04:55:42.941443+00	justlend	tron	USDD	1.4463270782139048e-05	\N	0	justlend	2025-09-10 04:55:42.976493+00
1157	justlend:USDT	0.01460528	2025-09-10 04:55:41.444+00	2025-09-10 04:55:42.941443+00	justlend	tron	USDT	0.01471216595588798	\N	0	justlend	2025-09-10 04:55:42.979119+00
1158	stride:stATOM	0.15140000	2025-09-10 04:55:41.203+00	2025-09-10 04:55:42.941443+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 04:55:42.982697+00
1159	stride:stTIA	0.11000000	2025-09-10 04:55:41.203+00	2025-09-10 04:55:42.941443+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 04:55:42.985874+00
1160	stride:stJUNO	0.22620000	2025-09-10 04:55:41.203+00	2025-09-10 04:55:42.941443+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 04:55:42.988483+00
1161	stride:stLUNA	0.17720000	2025-09-10 04:55:41.203+00	2025-09-10 04:55:42.941443+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 04:55:42.990425+00
1162	stride:stBAND	0.15430000	2025-09-10 04:55:41.203+00	2025-09-10 04:55:42.941443+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 04:55:42.993097+00
1464	stride:stATOM	0.15140000	2025-09-12 02:22:37.98+00	2025-09-12 02:22:39.750663+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:22:39.803551+00
1465	stride:stTIA	0.11000000	2025-09-12 02:22:37.98+00	2025-09-12 02:22:39.750663+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:22:39.806946+00
1467	stride:stLUNA	0.17720000	2025-09-12 02:22:37.98+00	2025-09-12 02:22:39.750663+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:22:39.812178+00
1292	aave:AUSD	0.04039597	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	avalanche	AUSD	0.04122066130486779	\N	\N	onchain	2025-09-11 00:49:44.023264+00
1165	aave:DAI	0.03642268	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 16:58:57.927306+00
1170	aave:DAI	0.03426161	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 16:58:57.927306+00
1167	aave:USDT	0.04194565	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:57.930713+00
1171	aave:USDT	0.03164895	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:57.930713+00
1164	aave:USDC	0.02157250	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:57.940604+00
1168	aave:USDC	0.04721941	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:57.940604+00
1169	aave:USDC	0.04801386	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:57.940604+00
1172	aave:USDC	0.05021439	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:57.940604+00
1173	aave:USDC	0.02546353	2025-09-10 16:58:56.019+00	2025-09-10 16:58:57.846202+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:57.940604+00
1291	aave:DAI	0.03540614	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:49:44.046654+00
1296	aave:DAI	0.03419503	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:49:44.046654+00
1289	aave:USDT	0.04410701	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.050227+00
1293	aave:USDT	0.04216455	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.050227+00
1297	aave:USDT	0.03241569	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.050227+00
1290	aave:USDC	0.02135411	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.059185+00
1294	aave:USDC	0.04707002	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.059185+00
1295	aave:USDC	0.04693225	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.059185+00
1298	aave:USDC	0.04813700	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.059185+00
1299	aave:USDC	0.02673131	2025-09-11 00:49:41.798+00	2025-09-11 00:49:43.988066+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.059185+00
1303	stride:stTIA	0.11000000	2025-09-11 00:49:41.8+00	2025-09-11 00:49:43.988066+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-11 00:49:44.078379+00
1304	stride:stJUNO	0.22620000	2025-09-11 00:49:41.8+00	2025-09-11 00:49:43.988066+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-11 00:49:44.082862+00
1305	stride:stLUNA	0.17720000	2025-09-11 00:49:41.8+00	2025-09-11 00:49:43.988066+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-11 00:49:44.087699+00
1306	stride:stBAND	0.15430000	2025-09-11 00:49:41.8+00	2025-09-11 00:49:43.988066+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-11 00:49:44.091808+00
1184	aave:AUSD	0.13780779	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	avalanche	AUSD	0.14772506918770545	\N	\N	onchain	2025-09-10 16:58:58.386827+00
1183	aave:DAI	0.03642268	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 16:58:58.397858+00
1188	aave:DAI	0.03426161	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 16:58:58.397858+00
1181	aave:USDT	0.04393592	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:58.399353+00
1185	aave:USDT	0.04194565	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:58.399353+00
1189	aave:USDT	0.03164895	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:58.399353+00
1182	aave:USDC	0.02157250	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.406214+00
1186	aave:USDC	0.04721941	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.406214+00
1187	aave:USDC	0.04801386	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.406214+00
1190	aave:USDC	0.05021439	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.406214+00
1191	aave:USDC	0.02546353	2025-09-10 16:58:56.014+00	2025-09-10 16:58:58.368559+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.406214+00
1192	justlend:USDD	0.00001452	2025-09-10 16:58:56.269+00	2025-09-10 16:58:58.368559+00	justlend	tron	USDD	1.4518438567145964e-05	\N	0	justlend	2025-09-10 16:58:58.409561+00
1193	justlend:USDT	0.01457255	2025-09-10 16:58:56.269+00	2025-09-10 16:58:58.368559+00	justlend	tron	USDT	0.014678948569817774	\N	0	justlend	2025-09-10 16:58:58.413428+00
1194	stride:stATOM	0.15140000	2025-09-10 16:58:56.017+00	2025-09-10 16:58:58.368559+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 16:58:58.418412+00
1195	stride:stTIA	0.11000000	2025-09-10 16:58:56.017+00	2025-09-10 16:58:58.368559+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 16:58:58.422367+00
1196	stride:stJUNO	0.22620000	2025-09-10 16:58:56.017+00	2025-09-10 16:58:58.368559+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 16:58:58.425882+00
1197	stride:stLUNA	0.17720000	2025-09-10 16:58:56.017+00	2025-09-10 16:58:58.368559+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 16:58:58.429554+00
1198	stride:stBAND	0.15430000	2025-09-10 16:58:56.017+00	2025-09-10 16:58:58.368559+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 16:58:58.433354+00
1202	aave:AUSD	0.13780779	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	avalanche	AUSD	0.14772506918770545	\N	\N	onchain	2025-09-10 16:58:58.65367+00
1201	aave:DAI	0.03642268	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 16:58:58.67227+00
1206	aave:DAI	0.03426161	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 16:58:58.67227+00
1199	aave:USDT	0.04393592	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:58.676589+00
1203	aave:USDT	0.04194565	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:58.676589+00
1207	aave:USDT	0.03164895	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 16:58:58.676589+00
1200	aave:USDC	0.02157250	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.685792+00
1204	aave:USDC	0.04721941	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.685792+00
1205	aave:USDC	0.04801386	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.685792+00
1208	aave:USDC	0.05021439	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.685792+00
1209	aave:USDC	0.02546353	2025-09-10 16:58:56.032+00	2025-09-10 16:58:58.621292+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 16:58:58.685792+00
1210	justlend:USDD	0.00001452	2025-09-10 16:58:56.322+00	2025-09-10 16:58:58.621292+00	justlend	tron	USDD	1.4518438567145964e-05	\N	0	justlend	2025-09-10 16:58:58.690232+00
1211	justlend:USDT	0.01457255	2025-09-10 16:58:56.322+00	2025-09-10 16:58:58.621292+00	justlend	tron	USDT	0.014678948569817774	\N	0	justlend	2025-09-10 16:58:58.694621+00
1212	stride:stATOM	0.15140000	2025-09-10 16:58:56.034+00	2025-09-10 16:58:58.621292+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 16:58:58.699365+00
1301	justlend:USDT	0.01472026	2025-09-11 00:49:42.103+00	2025-09-11 00:49:43.988066+00	justlend	tron	USDT	0.014828831082904337	\N	0	justlend	2025-09-11 00:49:44.069978+00
1626	stride:stATOM	0.15140000	2025-09-12 02:43:19.059+00	2025-09-12 02:43:20.88524+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:43:20.928943+00
1213	stride:stTIA	0.11000000	2025-09-10 16:58:56.034+00	2025-09-10 16:58:58.621292+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 16:58:58.703669+00
1214	stride:stJUNO	0.22620000	2025-09-10 16:58:56.034+00	2025-09-10 16:58:58.621292+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 16:58:58.708202+00
1215	stride:stLUNA	0.17720000	2025-09-10 16:58:56.034+00	2025-09-10 16:58:58.621292+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 16:58:58.713281+00
1216	stride:stBAND	0.15430000	2025-09-10 16:58:56.034+00	2025-09-10 16:58:58.621292+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 16:58:58.718328+00
1468	stride:stBAND	0.15430000	2025-09-12 02:22:37.98+00	2025-09-12 02:22:39.750663+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:22:39.814112+00
1310	aave:AUSD	0.04039597	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	avalanche	AUSD	0.04122066130486779	\N	\N	onchain	2025-09-11 00:49:44.26117+00
1309	aave:DAI	0.03540614	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:49:44.276074+00
1314	aave:DAI	0.03419503	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:49:44.276074+00
1308	aave:USDC	0.02135411	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.288188+00
1312	aave:USDC	0.04707002	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.288188+00
1220	aave:AUSD	0.11124248	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	avalanche	AUSD	0.11764693964842321	\N	\N	onchain	2025-09-10 17:15:09.564313+00
1238	aave:AUSD	0.11124248	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	avalanche	AUSD	0.11764693964842321	\N	\N	onchain	2025-09-10 17:15:09.586606+00
1219	aave:DAI	0.03642268	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 17:15:09.591633+00
1224	aave:DAI	0.03426161	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 17:15:09.591633+00
1217	aave:USDT	0.04398888	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.670935+00
1221	aave:USDT	0.04194565	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.670935+00
1225	aave:USDT	0.03164895	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.670935+00
1218	aave:USDC	0.02132562	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.685553+00
1222	aave:USDC	0.04721941	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.685553+00
1223	aave:USDC	0.04801386	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.685553+00
1226	aave:USDC	0.05021439	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.685553+00
1227	aave:USDC	0.02546353	2025-09-10 17:15:07.224+00	2025-09-10 17:15:09.463178+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.685553+00
1228	justlend:USDD	0.00001457	2025-09-10 17:15:07.458+00	2025-09-10 17:15:09.463178+00	justlend	tron	USDD	1.4565207082650744e-05	\N	0	justlend	2025-09-10 17:15:09.691696+00
1235	aave:USDT	0.04398888	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.693927+00
1239	aave:USDT	0.04194565	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.693927+00
1243	aave:USDT	0.03164895	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.693927+00
1229	justlend:USDT	0.01462147	2025-09-10 17:15:07.458+00	2025-09-10 17:15:09.463178+00	justlend	tron	USDT	0.014728587876205346	\N	0	justlend	2025-09-10 17:15:09.696832+00
1256	aave:AUSD	0.11124248	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	avalanche	AUSD	0.11764693964842321	\N	\N	onchain	2025-09-10 17:15:09.699838+00
1230	stride:stATOM	0.15140000	2025-09-10 17:15:07.225+00	2025-09-10 17:15:09.463178+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 17:15:09.702522+00
1236	aave:USDC	0.02132562	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.706383+00
1240	aave:USDC	0.04721941	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.706383+00
1241	aave:USDC	0.04801386	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.706383+00
1244	aave:USDC	0.05021439	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.706383+00
1245	aave:USDC	0.02546353	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.706383+00
1231	stride:stTIA	0.11000000	2025-09-10 17:15:07.225+00	2025-09-10 17:15:09.463178+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 17:15:09.709446+00
1246	justlend:USDD	0.00001457	2025-09-10 17:15:07.5+00	2025-09-10 17:15:09.561768+00	justlend	tron	USDD	1.4565207082650744e-05	\N	0	justlend	2025-09-10 17:15:09.713462+00
1232	stride:stJUNO	0.22620000	2025-09-10 17:15:07.225+00	2025-09-10 17:15:09.463178+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 17:15:09.71547+00
1247	justlend:USDT	0.01462147	2025-09-10 17:15:07.5+00	2025-09-10 17:15:09.561768+00	justlend	tron	USDT	0.014728587876205346	\N	0	justlend	2025-09-10 17:15:09.718191+00
1233	stride:stLUNA	0.17720000	2025-09-10 17:15:07.225+00	2025-09-10 17:15:09.463178+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 17:15:09.719441+00
1255	aave:DAI	0.03642268	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 17:15:09.722542+00
1260	aave:DAI	0.03426161	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 17:15:09.722542+00
1248	stride:stATOM	0.15140000	2025-09-10 17:15:07.232+00	2025-09-10 17:15:09.561768+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 17:15:09.722529+00
1234	stride:stBAND	0.15430000	2025-09-10 17:15:07.225+00	2025-09-10 17:15:09.463178+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 17:15:09.725433+00
1253	aave:USDT	0.04398888	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.72912+00
1257	aave:USDT	0.04194565	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.72912+00
1249	stride:stTIA	0.11000000	2025-09-10 17:15:07.232+00	2025-09-10 17:15:09.561768+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 17:15:09.729127+00
1250	stride:stJUNO	0.22620000	2025-09-10 17:15:07.232+00	2025-09-10 17:15:09.561768+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 17:15:09.736586+00
1251	stride:stLUNA	0.17720000	2025-09-10 17:15:07.232+00	2025-09-10 17:15:09.561768+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 17:15:09.74106+00
1252	stride:stBAND	0.15430000	2025-09-10 17:15:07.232+00	2025-09-10 17:15:09.561768+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 17:15:09.745188+00
1264	justlend:USDD	0.00001457	2025-09-10 17:15:07.43+00	2025-09-10 17:15:09.678293+00	justlend	tron	USDD	1.4565207082650744e-05	\N	0	justlend	2025-09-10 17:15:09.74786+00
1265	justlend:USDT	0.01462147	2025-09-10 17:15:07.43+00	2025-09-10 17:15:09.678293+00	justlend	tron	USDT	0.014728587876205346	\N	0	justlend	2025-09-10 17:15:09.753207+00
1266	stride:stATOM	0.15140000	2025-09-10 17:15:07.221+00	2025-09-10 17:15:09.678293+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-10 17:15:09.75843+00
1267	stride:stTIA	0.11000000	2025-09-10 17:15:07.221+00	2025-09-10 17:15:09.678293+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-10 17:15:09.761616+00
1268	stride:stJUNO	0.22620000	2025-09-10 17:15:07.221+00	2025-09-10 17:15:09.678293+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-10 17:15:09.765219+00
1269	stride:stLUNA	0.17720000	2025-09-10 17:15:07.221+00	2025-09-10 17:15:09.678293+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-10 17:15:09.770816+00
1270	stride:stBAND	0.15430000	2025-09-10 17:15:07.221+00	2025-09-10 17:15:09.678293+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-10 17:15:09.776071+00
1629	stride:stLUNA	0.17720000	2025-09-12 02:43:19.059+00	2025-09-12 02:43:20.88524+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:43:20.934976+00
1454	aave:AUSD	0.04915513	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:22:39.771631+00
1453	aave:DAI	0.03596252	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:22:39.786628+00
1458	aave:DAI	0.03557108	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:22:39.786628+00
1451	aave:USDT	0.04727410	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:39.789093+00
1261	aave:USDT	0.03164895	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	avalanche	USDT	0.0321551	\N	\N	llama	2025-09-10 17:15:09.72912+00
1455	aave:USDT	0.04445851	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:39.789093+00
1459	aave:USDT	0.03374488	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:39.789093+00
1452	aave:USDC	0.02408851	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.793567+00
1254	aave:USDC	0.02132562	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.743855+00
1258	aave:USDC	0.04721941	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.743855+00
1259	aave:USDC	0.04801386	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.743855+00
1262	aave:USDC	0.05021439	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.743855+00
1263	aave:USDC	0.02546353	2025-09-10 17:15:07.219+00	2025-09-10 17:15:09.678293+00	aave	celo	USDC	0.0257905	\N	\N	llama	2025-09-10 17:15:09.743855+00
1307	aave:USDT	0.04410701	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.28058+00
1311	aave:USDT	0.04216455	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.28058+00
1315	aave:USDT	0.03241569	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.28058+00
1313	aave:USDC	0.04693225	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.288188+00
1316	aave:USDC	0.04813700	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.288188+00
1317	aave:USDC	0.02673131	2025-09-11 00:49:41.783+00	2025-09-11 00:49:44.238166+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.288188+00
1320	stride:stATOM	0.15140000	2025-09-11 00:49:41.786+00	2025-09-11 00:49:44.238166+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-11 00:49:44.299698+00
1321	stride:stTIA	0.11000000	2025-09-11 00:49:41.786+00	2025-09-11 00:49:44.238166+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-11 00:49:44.303416+00
1322	stride:stJUNO	0.22620000	2025-09-11 00:49:41.786+00	2025-09-11 00:49:44.238166+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-11 00:49:44.308304+00
1323	stride:stLUNA	0.17720000	2025-09-11 00:49:41.786+00	2025-09-11 00:49:44.238166+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-11 00:49:44.314455+00
1324	stride:stBAND	0.15430000	2025-09-11 00:49:41.786+00	2025-09-11 00:49:44.238166+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-11 00:49:44.320316+00
1544	aave:AUSD	0.04915526	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:33:46.386907+00
1543	aave:DAI	0.03596252	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:33:46.407287+00
1541	aave:USDT	0.04727179	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.411842+00
1542	aave:USDC	0.02408851	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.418854+00
1328	aave:AUSD	0.04039597	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	avalanche	AUSD	0.04122066130486779	\N	\N	onchain	2025-09-11 00:49:44.440066+00
1327	aave:DAI	0.03540614	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:49:44.460265+00
1332	aave:DAI	0.03419503	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:49:44.460265+00
1325	aave:USDT	0.04410701	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.462502+00
1329	aave:USDT	0.04216455	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.462502+00
1333	aave:USDT	0.03241569	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:49:44.462502+00
1326	aave:USDC	0.02135411	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.47177+00
1330	aave:USDC	0.04707002	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.47177+00
1331	aave:USDC	0.04693225	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.47177+00
1334	aave:USDC	0.04813700	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.47177+00
1335	aave:USDC	0.02673131	2025-09-11 00:49:41.787+00	2025-09-11 00:49:44.413677+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:49:44.47177+00
1318	justlend:USDD	0.00001463	2025-09-11 00:49:42.059+00	2025-09-11 00:49:44.238166+00	justlend	tron	USDD	1.4632968433181404e-05	\N	0	justlend	2025-09-11 00:49:44.478759+00
1336	justlend:USDD	0.00001463	2025-09-11 00:49:42.059+00	2025-09-11 00:49:44.413677+00	justlend	tron	USDD	1.4632968433181404e-05	\N	0	justlend	2025-09-11 00:49:44.478759+00
1319	justlend:USDT	0.01472026	2025-09-11 00:49:42.059+00	2025-09-11 00:49:44.238166+00	justlend	tron	USDT	0.014828831082904337	\N	0	justlend	2025-09-11 00:49:44.484052+00
1337	justlend:USDT	0.01472026	2025-09-11 00:49:42.059+00	2025-09-11 00:49:44.413677+00	justlend	tron	USDT	0.014828831082904337	\N	0	justlend	2025-09-11 00:49:44.484052+00
1338	stride:stATOM	0.15140000	2025-09-11 00:49:41.788+00	2025-09-11 00:49:44.413677+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-11 00:49:44.491461+00
1339	stride:stTIA	0.11000000	2025-09-11 00:49:41.788+00	2025-09-11 00:49:44.413677+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-11 00:49:44.494123+00
1340	stride:stJUNO	0.22620000	2025-09-11 00:49:41.788+00	2025-09-11 00:49:44.413677+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-11 00:49:44.496841+00
1341	stride:stLUNA	0.17720000	2025-09-11 00:49:41.788+00	2025-09-11 00:49:44.413677+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-11 00:49:44.498597+00
1342	stride:stBAND	0.15430000	2025-09-11 00:49:41.788+00	2025-09-11 00:49:44.413677+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-11 00:49:44.502738+00
1364	aave:AUSD	0.04915513	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:04:18.084027+00
1363	aave:DAI	0.03596252	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:04:18.176646+00
1368	aave:DAI	0.03557098	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:04:18.176646+00
1361	aave:USDT	0.04728041	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:18.179323+00
1365	aave:USDT	0.04443383	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:18.179323+00
1369	aave:USDT	0.03473712	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:18.179323+00
1362	aave:USDC	0.02408848	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.188063+00
1366	aave:USDC	0.04613837	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.188063+00
1367	aave:USDC	0.04909716	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.188063+00
1370	aave:USDC	0.04870978	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.188063+00
1237	aave:DAI	0.03642268	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 17:15:09.688901+00
1242	aave:DAI	0.03426161	2025-09-10 17:15:07.231+00	2025-09-10 17:15:09.561768+00	aave	ethereum	DAI	0.0348553	\N	\N	llama	2025-09-10 17:15:09.688901+00
1274	aave:AUSD	0.04039620	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	avalanche	AUSD	0.04122090038428117	\N	\N	onchain	2025-09-11 00:43:23.074611+00
1346	aave:AUSD	0.04915513	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:04:17.88525+00
1273	aave:DAI	0.03540614	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:43:23.104338+00
1278	aave:DAI	0.03419503	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	ethereum	DAI	0.0347864	\N	\N	llama	2025-09-11 00:43:23.104338+00
1271	aave:USDT	0.04407856	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:43:23.109694+00
1275	aave:USDT	0.04216455	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:43:23.109694+00
1279	aave:USDT	0.03241569	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	avalanche	USDT	0.0329468	\N	\N	llama	2025-09-11 00:43:23.109694+00
1345	aave:DAI	0.03596252	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:04:17.901866+00
1350	aave:DAI	0.03557098	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:04:17.901866+00
1343	aave:USDT	0.04728041	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:17.906778+00
1347	aave:USDT	0.04443383	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:17.906778+00
1272	aave:USDC	0.02135411	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:43:23.118751+00
1276	aave:USDC	0.04707002	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:43:23.118751+00
1277	aave:USDC	0.04693225	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:43:23.118751+00
1280	aave:USDC	0.04813700	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:43:23.118751+00
1281	aave:USDC	0.02673131	2025-09-11 00:43:20.046+00	2025-09-11 00:43:23.049968+00	aave	celo	USDC	0.0270918	\N	\N	llama	2025-09-11 00:43:23.118751+00
1282	justlend:USDD	0.00001463	2025-09-11 00:43:20.413+00	2025-09-11 00:43:23.049968+00	justlend	tron	USDD	1.4632968433181404e-05	\N	0	justlend	2025-09-11 00:43:23.124271+00
1283	justlend:USDT	0.01459266	2025-09-11 00:43:20.413+00	2025-09-11 00:43:23.049968+00	justlend	tron	USDT	0.01469936113431003	\N	0	justlend	2025-09-11 00:43:23.128889+00
1284	stride:stATOM	0.15140000	2025-09-11 00:43:20.068+00	2025-09-11 00:43:23.049968+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-11 00:43:23.133598+00
1285	stride:stTIA	0.11000000	2025-09-11 00:43:20.068+00	2025-09-11 00:43:23.049968+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-11 00:43:23.137862+00
1286	stride:stJUNO	0.22620000	2025-09-11 00:43:20.068+00	2025-09-11 00:43:23.049968+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-11 00:43:23.142582+00
1287	stride:stLUNA	0.17720000	2025-09-11 00:43:20.068+00	2025-09-11 00:43:23.049968+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-11 00:43:23.146732+00
1288	stride:stBAND	0.15430000	2025-09-11 00:43:20.068+00	2025-09-11 00:43:23.049968+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-11 00:43:23.150474+00
1351	aave:USDT	0.03473712	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:17.906778+00
1344	aave:USDC	0.02408848	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:17.914524+00
1348	aave:USDC	0.04613837	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:17.914524+00
1349	aave:USDC	0.04909716	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:17.914524+00
1352	aave:USDC	0.04870978	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:17.914524+00
1353	aave:USDC	0.03718904	2025-09-12 02:04:16.093+00	2025-09-12 02:04:17.835753+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:17.914524+00
1354	justlend:USDD	0.00001475	2025-09-12 02:04:16.324+00	2025-09-12 02:04:17.835753+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:04:17.917294+00
1355	justlend:USDT	0.01474150	2025-09-12 02:04:16.324+00	2025-09-12 02:04:17.835753+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:04:17.921728+00
1356	stride:stATOM	0.15140000	2025-09-12 02:04:16.096+00	2025-09-12 02:04:17.835753+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:04:17.924869+00
1357	stride:stTIA	0.11000000	2025-09-12 02:04:16.096+00	2025-09-12 02:04:17.835753+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:04:17.929714+00
1358	stride:stJUNO	0.22620000	2025-09-12 02:04:16.096+00	2025-09-12 02:04:17.835753+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:04:17.933176+00
1359	stride:stLUNA	0.17720000	2025-09-12 02:04:16.096+00	2025-09-12 02:04:17.835753+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:04:18.015682+00
1360	stride:stBAND	0.15430000	2025-09-12 02:04:16.096+00	2025-09-12 02:04:17.835753+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:04:18.075564+00
1382	aave:AUSD	0.04915513	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:04:18.177815+00
1372	justlend:USDD	0.00001475	2025-09-12 02:04:16.361+00	2025-09-12 02:04:18.020959+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:04:18.19065+00
1381	aave:DAI	0.03596252	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:04:18.19205+00
1386	aave:DAI	0.03557098	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:04:18.19205+00
1373	justlend:USDT	0.01474150	2025-09-12 02:04:16.361+00	2025-09-12 02:04:18.020959+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:04:18.193353+00
1379	aave:USDT	0.04728041	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:18.194574+00
1383	aave:USDT	0.04443383	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:18.194574+00
1387	aave:USDT	0.03473712	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:04:18.194574+00
1375	stride:stTIA	0.11000000	2025-09-12 02:04:16.111+00	2025-09-12 02:04:18.020959+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:04:18.19807+00
1380	aave:USDC	0.02408848	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.199289+00
1384	aave:USDC	0.04613837	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.199289+00
1376	stride:stJUNO	0.22620000	2025-09-12 02:04:16.111+00	2025-09-12 02:04:18.020959+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:04:18.200469+00
1390	justlend:USDD	0.00001475	2025-09-12 02:04:16.322+00	2025-09-12 02:04:18.162659+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:04:18.202144+00
1377	stride:stLUNA	0.17720000	2025-09-12 02:04:16.111+00	2025-09-12 02:04:18.020959+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:04:18.203351+00
1391	justlend:USDT	0.01474150	2025-09-12 02:04:16.322+00	2025-09-12 02:04:18.162659+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:04:18.20438+00
1378	stride:stBAND	0.15430000	2025-09-12 02:04:16.111+00	2025-09-12 02:04:18.020959+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:04:18.205578+00
1392	stride:stATOM	0.15140000	2025-09-12 02:04:16.098+00	2025-09-12 02:04:18.162659+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:04:18.206633+00
1393	stride:stTIA	0.11000000	2025-09-12 02:04:16.098+00	2025-09-12 02:04:18.162659+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:04:18.208973+00
1394	stride:stJUNO	0.22620000	2025-09-12 02:04:16.098+00	2025-09-12 02:04:18.162659+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:04:18.210889+00
1395	stride:stLUNA	0.17720000	2025-09-12 02:04:16.098+00	2025-09-12 02:04:18.162659+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:04:18.212384+00
1456	aave:USDC	0.04618592	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.793567+00
1385	aave:USDC	0.04909716	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.199289+00
1388	aave:USDC	0.04870978	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.199289+00
1389	aave:USDC	0.03718904	2025-09-12 02:04:16.097+00	2025-09-12 02:04:18.162659+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.199289+00
1396	stride:stBAND	0.15430000	2025-09-12 02:04:16.098+00	2025-09-12 02:04:18.162659+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:04:18.213875+00
1457	aave:USDC	0.04907527	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.793567+00
1460	aave:USDC	0.04737011	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.793567+00
1461	aave:USDC	0.03718904	2025-09-12 02:22:37.979+00	2025-09-12 02:22:39.750663+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.793567+00
1462	justlend:USDD	0.00001475	2025-09-12 02:22:38.236+00	2025-09-12 02:22:39.750663+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:22:39.796765+00
1463	justlend:USDT	0.01474150	2025-09-12 02:22:38.236+00	2025-09-12 02:22:39.750663+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:22:39.799344+00
1466	stride:stJUNO	0.22620000	2025-09-12 02:22:37.98+00	2025-09-12 02:22:39.750663+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:22:39.810172+00
1472	aave:AUSD	0.04915513	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:22:39.934794+00
1471	aave:DAI	0.03596252	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:22:39.946138+00
1476	aave:DAI	0.03557108	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:22:39.946138+00
1469	aave:USDT	0.04727410	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:39.948792+00
1473	aave:USDT	0.04445851	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:39.948792+00
1477	aave:USDT	0.03374488	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:39.948792+00
1470	aave:USDC	0.02408851	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.952378+00
1474	aave:USDC	0.04618592	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.952378+00
1475	aave:USDC	0.04907527	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.952378+00
1478	aave:USDC	0.04737011	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.952378+00
1479	aave:USDC	0.03718904	2025-09-12 02:22:37.994+00	2025-09-12 02:22:39.917613+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:39.952378+00
1480	justlend:USDD	0.00001475	2025-09-12 02:22:38.311+00	2025-09-12 02:22:39.917613+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:22:39.95386+00
1481	justlend:USDT	0.01474150	2025-09-12 02:22:38.311+00	2025-09-12 02:22:39.917613+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:22:39.955648+00
1482	stride:stATOM	0.15140000	2025-09-12 02:22:37.995+00	2025-09-12 02:22:39.917613+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:22:39.957713+00
1483	stride:stTIA	0.11000000	2025-09-12 02:22:37.995+00	2025-09-12 02:22:39.917613+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:22:39.959921+00
1484	stride:stJUNO	0.22620000	2025-09-12 02:22:37.995+00	2025-09-12 02:22:39.917613+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:22:39.961556+00
1485	stride:stLUNA	0.17720000	2025-09-12 02:22:37.995+00	2025-09-12 02:22:39.917613+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:22:39.972716+00
1486	stride:stBAND	0.15430000	2025-09-12 02:22:37.995+00	2025-09-12 02:22:39.917613+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:22:39.975874+00
1490	aave:AUSD	0.04915513	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:22:40.084556+00
1489	aave:DAI	0.03596252	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:22:40.094315+00
1494	aave:DAI	0.03557108	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:22:40.094315+00
1487	aave:USDT	0.04727410	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:40.096305+00
1491	aave:USDT	0.04445851	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:40.096305+00
1495	aave:USDT	0.03374488	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:22:40.096305+00
1488	aave:USDC	0.02408851	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:40.101069+00
1492	aave:USDC	0.04618592	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:40.101069+00
1493	aave:USDC	0.04907527	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:40.101069+00
1496	aave:USDC	0.04737011	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:40.101069+00
1497	aave:USDC	0.03718904	2025-09-12 02:22:37.982+00	2025-09-12 02:22:40.070472+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:22:40.101069+00
1498	justlend:USDD	0.00001475	2025-09-12 02:22:38.245+00	2025-09-12 02:22:40.070472+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:22:40.103036+00
1499	justlend:USDT	0.01474150	2025-09-12 02:22:38.245+00	2025-09-12 02:22:40.070472+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:22:40.105273+00
1500	stride:stATOM	0.15140000	2025-09-12 02:22:37.983+00	2025-09-12 02:22:40.070472+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:22:40.107359+00
1501	stride:stTIA	0.11000000	2025-09-12 02:22:37.983+00	2025-09-12 02:22:40.070472+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:22:40.109014+00
1502	stride:stJUNO	0.22620000	2025-09-12 02:22:37.983+00	2025-09-12 02:22:40.070472+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:22:40.110412+00
1503	stride:stLUNA	0.17720000	2025-09-12 02:22:37.983+00	2025-09-12 02:22:40.070472+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:22:40.111813+00
1504	stride:stBAND	0.15430000	2025-09-12 02:22:37.983+00	2025-09-12 02:22:40.070472+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:22:40.11358+00
1548	aave:DAI	0.03557108	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:33:46.407287+00
1545	aave:USDT	0.04445851	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.411842+00
1546	aave:USDC	0.04618592	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.418854+00
1547	aave:USDC	0.04907527	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.418854+00
1552	justlend:USDD	0.00001475	2025-09-12 02:33:44.881+00	2025-09-12 02:33:46.369762+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:33:46.422979+00
1553	justlend:USDT	0.01474150	2025-09-12 02:33:44.881+00	2025-09-12 02:33:46.369762+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:33:46.425171+00
1554	stride:stATOM	0.15140000	2025-09-12 02:33:44.645+00	2025-09-12 02:33:46.369762+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:33:46.427398+00
1555	stride:stTIA	0.11000000	2025-09-12 02:33:44.645+00	2025-09-12 02:33:46.369762+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:33:46.429295+00
1556	stride:stJUNO	0.22620000	2025-09-12 02:33:44.645+00	2025-09-12 02:33:46.369762+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:33:46.431328+00
1557	stride:stLUNA	0.17720000	2025-09-12 02:33:44.645+00	2025-09-12 02:33:46.369762+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:33:46.433446+00
1371	aave:USDC	0.03718904	2025-09-12 02:04:16.109+00	2025-09-12 02:04:18.020959+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:04:18.188063+00
1374	stride:stATOM	0.15140000	2025-09-12 02:04:16.111+00	2025-09-12 02:04:18.020959+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:04:18.195628+00
1828	stride:stBAND	0.15430000	2025-09-14 19:42:11.36+00	2025-09-14 19:42:13.988766+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:42:14.222445+00
1508	aave:AUSD	0.04915526	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:33:46.153336+00
1400	aave:AUSD	0.04915513	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:06:54.134611+00
1507	aave:DAI	0.03596252	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:33:46.161004+00
1512	aave:DAI	0.03557108	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:33:46.161004+00
1505	aave:USDT	0.04727179	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.162525+00
1509	aave:USDT	0.04445851	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.162525+00
1513	aave:USDT	0.03374488	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.162525+00
1399	aave:DAI	0.03596252	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:06:54.239389+00
1404	aave:DAI	0.03557098	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:06:54.239389+00
1506	aave:USDC	0.02408851	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.165499+00
1510	aave:USDC	0.04618592	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.165499+00
1511	aave:USDC	0.04907527	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.165499+00
1516	justlend:USDD	0.00001475	2025-09-12 02:33:44.685+00	2025-09-12 02:33:46.105149+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:33:46.167532+00
1517	justlend:USDT	0.01474150	2025-09-12 02:33:44.685+00	2025-09-12 02:33:46.105149+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:33:46.169464+00
1518	stride:stATOM	0.15140000	2025-09-12 02:33:44.631+00	2025-09-12 02:33:46.105149+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:33:46.171148+00
1519	stride:stTIA	0.11000000	2025-09-12 02:33:44.631+00	2025-09-12 02:33:46.105149+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:33:46.173196+00
1520	stride:stJUNO	0.22620000	2025-09-12 02:33:44.631+00	2025-09-12 02:33:46.105149+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:33:46.174946+00
1521	stride:stLUNA	0.17720000	2025-09-12 02:33:44.631+00	2025-09-12 02:33:46.105149+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:33:46.176766+00
1522	stride:stBAND	0.15430000	2025-09-12 02:33:44.631+00	2025-09-12 02:33:46.105149+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:33:46.178263+00
1397	aave:USDT	0.04728050	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.241346+00
1401	aave:USDT	0.04443383	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.241346+00
1405	aave:USDT	0.03473712	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.241346+00
1398	aave:USDC	0.02408848	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.247314+00
1402	aave:USDC	0.04613837	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.247314+00
1403	aave:USDC	0.04909716	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.247314+00
1406	aave:USDC	0.04870978	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.247314+00
1407	aave:USDC	0.03718904	2025-09-12 02:06:52.34+00	2025-09-12 02:06:54.119381+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.247314+00
1408	justlend:USDD	0.00001475	2025-09-12 02:06:52.565+00	2025-09-12 02:06:54.119381+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:06:54.249666+00
1418	aave:AUSD	0.04915513	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:06:54.250911+00
1409	justlend:USDT	0.01474150	2025-09-12 02:06:52.565+00	2025-09-12 02:06:54.119381+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:06:54.252375+00
1410	stride:stATOM	0.15140000	2025-09-12 02:06:52.343+00	2025-09-12 02:06:54.119381+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:06:54.255646+00
1411	stride:stTIA	0.11000000	2025-09-12 02:06:52.343+00	2025-09-12 02:06:54.119381+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:06:54.258031+00
1412	stride:stJUNO	0.22620000	2025-09-12 02:06:52.343+00	2025-09-12 02:06:54.119381+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:06:54.260455+00
1417	aave:DAI	0.03596252	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:06:54.261512+00
1422	aave:DAI	0.03557098	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:06:54.261512+00
1413	stride:stLUNA	0.17720000	2025-09-12 02:06:52.343+00	2025-09-12 02:06:54.119381+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:06:54.262774+00
1415	aave:USDT	0.04728050	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.325317+00
1414	stride:stBAND	0.15430000	2025-09-12 02:06:52.343+00	2025-09-12 02:06:54.119381+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:06:54.325317+00
1419	aave:USDT	0.04443383	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.325317+00
1423	aave:USDT	0.03473712	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.325317+00
1416	aave:USDC	0.02408848	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.348254+00
1420	aave:USDC	0.04613837	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.348254+00
1421	aave:USDC	0.04909716	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.348254+00
1424	aave:USDC	0.04870978	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.348254+00
1425	aave:USDC	0.03718904	2025-09-12 02:06:52.345+00	2025-09-12 02:06:54.239566+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.348254+00
1426	justlend:USDD	0.00001475	2025-09-12 02:06:52.574+00	2025-09-12 02:06:54.239566+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:06:54.350672+00
1427	justlend:USDT	0.01474150	2025-09-12 02:06:52.574+00	2025-09-12 02:06:54.239566+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:06:54.352755+00
1436	aave:AUSD	0.04915513	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	avalanche	AUSD	0.0503798046373749	\N	\N	onchain	2025-09-12 02:06:54.353809+00
1428	stride:stATOM	0.15140000	2025-09-12 02:06:52.346+00	2025-09-12 02:06:54.239566+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:06:54.355192+00
1429	stride:stTIA	0.11000000	2025-09-12 02:06:52.346+00	2025-09-12 02:06:54.239566+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:06:54.357316+00
1430	stride:stJUNO	0.22620000	2025-09-12 02:06:52.346+00	2025-09-12 02:06:54.239566+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:06:54.35966+00
1431	stride:stLUNA	0.17720000	2025-09-12 02:06:52.346+00	2025-09-12 02:06:54.239566+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:06:54.362281+00
1435	aave:DAI	0.03596252	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:06:54.363394+00
1432	stride:stBAND	0.15430000	2025-09-12 02:06:52.346+00	2025-09-12 02:06:54.239566+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:06:54.364671+00
1433	aave:USDT	0.04728050	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.365813+00
1434	aave:USDC	0.02408848	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.369323+00
1514	aave:USDC	0.04737011	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.165499+00
1515	aave:USDC	0.03718904	2025-09-12 02:33:44.63+00	2025-09-12 02:33:46.105149+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.165499+00
1440	aave:DAI	0.03557098	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	ethereum	DAI	0.0362112	\N	\N	llama	2025-09-12 02:06:54.363394+00
1437	aave:USDT	0.04443383	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.365813+00
1441	aave:USDT	0.03473712	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	avalanche	USDT	0.0353475	\N	\N	llama	2025-09-12 02:06:54.365813+00
1438	aave:USDC	0.04613837	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.369323+00
1439	aave:USDC	0.04909716	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.369323+00
1442	aave:USDC	0.04870978	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.369323+00
1443	aave:USDC	0.03718904	2025-09-12 02:06:52.357+00	2025-09-12 02:06:54.329974+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:06:54.369323+00
1444	justlend:USDD	0.00001475	2025-09-12 02:06:52.635+00	2025-09-12 02:06:54.329974+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:06:54.370873+00
1445	justlend:USDT	0.01474150	2025-09-12 02:06:52.635+00	2025-09-12 02:06:54.329974+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:06:54.372325+00
1446	stride:stATOM	0.15140000	2025-09-12 02:06:52.358+00	2025-09-12 02:06:54.329974+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:06:54.37388+00
1447	stride:stTIA	0.11000000	2025-09-12 02:06:52.358+00	2025-09-12 02:06:54.329974+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:06:54.375345+00
1448	stride:stJUNO	0.22620000	2025-09-12 02:06:52.358+00	2025-09-12 02:06:54.329974+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:06:54.376633+00
1449	stride:stLUNA	0.17720000	2025-09-12 02:06:52.358+00	2025-09-12 02:06:54.329974+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:06:54.378005+00
1450	stride:stBAND	0.15430000	2025-09-12 02:06:52.358+00	2025-09-12 02:06:54.329974+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:06:54.379601+00
1526	aave:AUSD	0.04915526	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:33:46.296844+00
1525	aave:DAI	0.03596252	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:33:46.304569+00
1530	aave:DAI	0.03557108	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:33:46.304569+00
1523	aave:USDT	0.04727179	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.306218+00
1527	aave:USDT	0.04445851	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.306218+00
1531	aave:USDT	0.03374488	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.306218+00
1524	aave:USDC	0.02408851	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.309932+00
1528	aave:USDC	0.04618592	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.309932+00
1529	aave:USDC	0.04907527	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.309932+00
1532	aave:USDC	0.04737011	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.309932+00
1533	aave:USDC	0.03718904	2025-09-12 02:33:44.633+00	2025-09-12 02:33:46.261219+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.309932+00
1534	justlend:USDD	0.00001475	2025-09-12 02:33:44.892+00	2025-09-12 02:33:46.261219+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:33:46.311673+00
1535	justlend:USDT	0.01474150	2025-09-12 02:33:44.892+00	2025-09-12 02:33:46.261219+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:33:46.313214+00
1536	stride:stATOM	0.15140000	2025-09-12 02:33:44.634+00	2025-09-12 02:33:46.261219+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:33:46.369812+00
1537	stride:stTIA	0.11000000	2025-09-12 02:33:44.634+00	2025-09-12 02:33:46.261219+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:33:46.372931+00
1538	stride:stJUNO	0.22620000	2025-09-12 02:33:44.634+00	2025-09-12 02:33:46.261219+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:33:46.377136+00
1539	stride:stLUNA	0.17720000	2025-09-12 02:33:44.634+00	2025-09-12 02:33:46.261219+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:33:46.381008+00
1540	stride:stBAND	0.15430000	2025-09-12 02:33:44.634+00	2025-09-12 02:33:46.261219+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:33:46.385856+00
1549	aave:USDT	0.03374488	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:33:46.411842+00
1550	aave:USDC	0.04737011	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.418854+00
1551	aave:USDC	0.03718904	2025-09-12 02:33:44.644+00	2025-09-12 02:33:46.369762+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:33:46.418854+00
1558	stride:stBAND	0.15430000	2025-09-12 02:33:44.645+00	2025-09-12 02:33:46.369762+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:33:46.435606+00
1562	aave:AUSD	0.04915526	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:39:25.673785+00
1561	aave:DAI	0.03596252	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:39:25.681886+00
1566	aave:DAI	0.03557108	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:39:25.681886+00
1559	aave:USDT	0.04727180	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:25.683371+00
1563	aave:USDT	0.04445851	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:25.683371+00
1567	aave:USDT	0.03374488	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:25.683371+00
1560	aave:USDC	0.02408857	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.686579+00
1564	aave:USDC	0.04618592	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.686579+00
1565	aave:USDC	0.04907527	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.686579+00
1568	aave:USDC	0.04737011	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.686579+00
1569	aave:USDC	0.03718904	2025-09-12 02:39:24.367+00	2025-09-12 02:39:25.65619+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.686579+00
1570	justlend:USDD	0.00001475	2025-09-12 02:39:24.433+00	2025-09-12 02:39:25.65619+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:39:25.688392+00
1571	justlend:USDT	0.01474150	2025-09-12 02:39:24.433+00	2025-09-12 02:39:25.65619+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:39:25.690166+00
1572	stride:stATOM	0.15140000	2025-09-12 02:39:24.368+00	2025-09-12 02:39:25.65619+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:39:25.692401+00
1573	stride:stTIA	0.11000000	2025-09-12 02:39:24.368+00	2025-09-12 02:39:25.65619+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:39:25.695857+00
1574	stride:stJUNO	0.22620000	2025-09-12 02:39:24.368+00	2025-09-12 02:39:25.65619+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:39:25.697657+00
1575	stride:stLUNA	0.17720000	2025-09-12 02:39:24.368+00	2025-09-12 02:39:25.65619+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:39:25.699205+00
1576	stride:stBAND	0.15430000	2025-09-12 02:39:24.368+00	2025-09-12 02:39:25.65619+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:39:25.700772+00
1579	aave:DAI	0.03596252	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:39:25.919032+00
1577	aave:USDT	0.04727180	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:25.927332+00
2212	aave:USDT	0.09747620	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.550662+00
1616	aave:AUSD	0.04915526	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:43:20.907971+00
1996	aave:USDT	0.04704540	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.19505+00
2000	aave:USDT	0.03455881	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.19505+00
1813	aave:DAI	0.03613820	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:42:14.172552+00
1816	aave:USDT	0.04749504	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.176918+00
1820	aave:USDT	0.03430393	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.176918+00
1615	aave:DAI	0.03596252	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:43:20.917251+00
1620	aave:DAI	0.03557108	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:43:20.917251+00
1580	aave:AUSD	0.04915526	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:39:25.907445+00
1613	aave:USDT	0.04727762	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:43:20.919481+00
1617	aave:USDT	0.04445851	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:43:20.919481+00
1621	aave:USDT	0.03374488	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:43:20.919481+00
1614	aave:USDC	0.02408756	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:43:20.923301+00
1618	aave:USDC	0.04618592	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:43:20.923301+00
1619	aave:USDC	0.04907527	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:43:20.923301+00
1622	aave:USDC	0.04737011	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:43:20.923301+00
1584	aave:DAI	0.03557108	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:39:25.919032+00
1581	aave:USDT	0.04445851	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:25.927332+00
1585	aave:USDT	0.03374488	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:25.927332+00
1623	aave:USDC	0.03718904	2025-09-12 02:43:19.025+00	2025-09-12 02:43:20.88524+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:43:20.923301+00
1624	justlend:USDD	0.00001475	2025-09-12 02:43:19.332+00	2025-09-12 02:43:20.88524+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:43:20.924997+00
1625	justlend:USDT	0.01474150	2025-09-12 02:43:19.332+00	2025-09-12 02:43:20.88524+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:43:20.926826+00
1627	stride:stTIA	0.11000000	2025-09-12 02:43:19.059+00	2025-09-12 02:43:20.88524+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:43:20.931001+00
1628	stride:stJUNO	0.22620000	2025-09-12 02:43:19.059+00	2025-09-12 02:43:20.88524+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:43:20.932829+00
1578	aave:USDC	0.02408857	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.937328+00
1582	aave:USDC	0.04618592	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.937328+00
1583	aave:USDC	0.04907527	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.937328+00
1586	aave:USDC	0.04737011	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.937328+00
1587	aave:USDC	0.03718904	2025-09-12 02:39:24.382+00	2025-09-12 02:39:25.894025+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:25.937328+00
1588	justlend:USDD	0.00001475	2025-09-12 02:39:24.596+00	2025-09-12 02:39:25.894025+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:39:25.939583+00
1589	justlend:USDT	0.01474150	2025-09-12 02:39:24.596+00	2025-09-12 02:39:25.894025+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:39:25.941152+00
1590	stride:stATOM	0.15140000	2025-09-12 02:39:24.383+00	2025-09-12 02:39:25.894025+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:39:25.942738+00
1591	stride:stTIA	0.11000000	2025-09-12 02:39:24.383+00	2025-09-12 02:39:25.894025+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:39:25.944402+00
1592	stride:stJUNO	0.22620000	2025-09-12 02:39:24.383+00	2025-09-12 02:39:25.894025+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:39:25.946022+00
1593	stride:stLUNA	0.17720000	2025-09-12 02:39:24.383+00	2025-09-12 02:39:25.894025+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:39:25.947496+00
1594	stride:stBAND	0.15430000	2025-09-12 02:39:24.383+00	2025-09-12 02:39:25.894025+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:39:25.948938+00
1630	stride:stBAND	0.15430000	2025-09-12 02:43:19.059+00	2025-09-12 02:43:20.88524+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:43:20.936752+00
1652	aave:AUSD	0.04879469	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	avalanche	AUSD	0.05000132509519428	\N	\N	onchain	2025-09-12 03:05:30.669288+00
1651	aave:DAI	0.04250618	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:05:30.681712+00
1656	aave:DAI	0.03557108	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:05:30.681712+00
1653	aave:USDT	0.04445851	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.68538+00
1654	aave:USDC	0.04618592	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.690538+00
1655	aave:USDC	0.04907527	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.690538+00
1598	aave:AUSD	0.04915526	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	avalanche	AUSD	0.050379947728938834	\N	\N	onchain	2025-09-12 02:39:26.272941+00
1597	aave:DAI	0.03596252	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:39:26.27932+00
1602	aave:DAI	0.03557108	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 02:39:26.27932+00
1595	aave:USDT	0.04727180	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:26.280975+00
1599	aave:USDT	0.04445851	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:26.280975+00
1603	aave:USDT	0.03374488	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 02:39:26.280975+00
1596	aave:USDC	0.02408857	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:26.286025+00
1600	aave:USDC	0.04618592	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:26.286025+00
1601	aave:USDC	0.04907527	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:26.286025+00
1604	aave:USDC	0.04737011	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:26.286025+00
1605	aave:USDC	0.03718904	2025-09-12 02:39:24.37+00	2025-09-12 02:39:26.260297+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 02:39:26.286025+00
1606	justlend:USDD	0.00001475	2025-09-12 02:39:24.6+00	2025-09-12 02:39:26.260297+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 02:39:26.287716+00
1607	justlend:USDT	0.01474150	2025-09-12 02:39:24.6+00	2025-09-12 02:39:26.260297+00	justlend	tron	USDT	0.01485038880985412	\N	0	justlend	2025-09-12 02:39:26.289191+00
1608	stride:stATOM	0.15140000	2025-09-12 02:39:24.371+00	2025-09-12 02:39:26.260297+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 02:39:26.290608+00
1609	stride:stTIA	0.11000000	2025-09-12 02:39:24.371+00	2025-09-12 02:39:26.260297+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 02:39:26.292+00
1610	stride:stJUNO	0.22620000	2025-09-12 02:39:24.371+00	2025-09-12 02:39:26.260297+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 02:39:26.293288+00
1611	stride:stLUNA	0.17720000	2025-09-12 02:39:24.371+00	2025-09-12 02:39:26.260297+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 02:39:26.294774+00
1612	stride:stBAND	0.15430000	2025-09-12 02:39:24.371+00	2025-09-12 02:39:26.260297+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 02:39:26.296136+00
1831	aave:DAI	0.03613820	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:42:14.183323+00
1634	aave:AUSD	0.04879469	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	avalanche	AUSD	0.05000132509519428	\N	\N	onchain	2025-09-12 03:05:30.466968+00
1633	aave:DAI	0.04250618	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:05:30.664506+00
1638	aave:DAI	0.03557108	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:05:30.664506+00
1631	aave:USDT	0.04741104	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.667681+00
1635	aave:USDT	0.04445851	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.667681+00
1639	aave:USDT	0.03374488	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.667681+00
1670	aave:AUSD	0.04879469	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	avalanche	AUSD	0.05000132509519428	\N	\N	onchain	2025-09-12 03:05:30.67252+00
1632	aave:USDC	0.02408758	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.67405+00
1636	aave:USDC	0.04618592	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.67405+00
1637	aave:USDC	0.04907527	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.67405+00
1640	aave:USDC	0.04737011	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.67405+00
1641	aave:USDC	0.03718904	2025-09-12 03:05:28.494+00	2025-09-12 03:05:30.349942+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.67405+00
1642	justlend:USDD	0.00001475	2025-09-12 03:05:28.751+00	2025-09-12 03:05:30.349942+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 03:05:30.676765+00
1643	justlend:USDT	0.01474159	2025-09-12 03:05:28.751+00	2025-09-12 03:05:30.349942+00	justlend	tron	USDT	0.014850485042984252	\N	0	justlend	2025-09-12 03:05:30.679889+00
1644	stride:stATOM	0.15140000	2025-09-12 03:05:28.502+00	2025-09-12 03:05:30.349942+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:05:30.683387+00
1669	aave:DAI	0.04250618	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:05:30.685326+00
1674	aave:DAI	0.03557108	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:05:30.685326+00
1649	aave:USDT	0.04741104	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.68538+00
1657	aave:USDT	0.03374488	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.68538+00
1645	stride:stTIA	0.11000000	2025-09-12 03:05:28.502+00	2025-09-12 03:05:30.349942+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:05:30.686765+00
1667	aave:USDT	0.04741104	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.688044+00
1671	aave:USDT	0.04445851	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.688044+00
1675	aave:USDT	0.03374488	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:05:30.688044+00
1646	stride:stJUNO	0.22620000	2025-09-12 03:05:28.502+00	2025-09-12 03:05:30.349942+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:05:30.689367+00
1650	aave:USDC	0.02408758	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.690538+00
1658	aave:USDC	0.04737011	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.690538+00
1659	aave:USDC	0.03718904	2025-09-12 03:05:28.506+00	2025-09-12 03:05:30.466916+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.690538+00
1647	stride:stLUNA	0.17720000	2025-09-12 03:05:28.502+00	2025-09-12 03:05:30.349942+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:05:30.692075+00
1660	justlend:USDD	0.00001475	2025-09-12 03:05:28.757+00	2025-09-12 03:05:30.466916+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 03:05:30.693288+00
1668	aave:USDC	0.02408758	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.693309+00
1672	aave:USDC	0.04618592	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.693309+00
1673	aave:USDC	0.04907527	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.693309+00
1676	aave:USDC	0.04737011	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.693309+00
1677	aave:USDC	0.03718904	2025-09-12 03:05:28.513+00	2025-09-12 03:05:30.539547+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:05:30.693309+00
1648	stride:stBAND	0.15430000	2025-09-12 03:05:28.502+00	2025-09-12 03:05:30.349942+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:05:30.694271+00
1678	justlend:USDD	0.00001475	2025-09-12 03:05:28.792+00	2025-09-12 03:05:30.539547+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 03:05:30.695306+00
1661	justlend:USDT	0.01474159	2025-09-12 03:05:28.757+00	2025-09-12 03:05:30.466916+00	justlend	tron	USDT	0.014850485042984252	\N	0	justlend	2025-09-12 03:05:30.695412+00
1679	justlend:USDT	0.01474159	2025-09-12 03:05:28.792+00	2025-09-12 03:05:30.539547+00	justlend	tron	USDT	0.014850485042984252	\N	0	justlend	2025-09-12 03:05:30.697955+00
1662	stride:stATOM	0.15140000	2025-09-12 03:05:28.511+00	2025-09-12 03:05:30.466916+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:05:30.698021+00
1680	stride:stATOM	0.15140000	2025-09-12 03:05:28.515+00	2025-09-12 03:05:30.539547+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:05:30.701506+00
1663	stride:stTIA	0.11000000	2025-09-12 03:05:28.511+00	2025-09-12 03:05:30.466916+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:05:30.702746+00
1681	stride:stTIA	0.11000000	2025-09-12 03:05:28.515+00	2025-09-12 03:05:30.539547+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:05:30.703715+00
1664	stride:stJUNO	0.22620000	2025-09-12 03:05:28.511+00	2025-09-12 03:05:30.466916+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:05:30.704734+00
1682	stride:stJUNO	0.22620000	2025-09-12 03:05:28.515+00	2025-09-12 03:05:30.539547+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:05:30.706037+00
1665	stride:stLUNA	0.17720000	2025-09-12 03:05:28.511+00	2025-09-12 03:05:30.466916+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:05:30.707077+00
1683	stride:stLUNA	0.17720000	2025-09-12 03:05:28.515+00	2025-09-12 03:05:30.539547+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:05:30.70844+00
1666	stride:stBAND	0.15430000	2025-09-12 03:05:28.511+00	2025-09-12 03:05:30.466916+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:05:30.70973+00
1684	stride:stBAND	0.15430000	2025-09-12 03:05:28.515+00	2025-09-12 03:05:30.539547+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:05:30.711088+00
1688	aave:AUSD	0.04879469	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	avalanche	AUSD	0.05000132509519428	\N	\N	onchain	2025-09-12 03:07:25.893657+00
1687	aave:DAI	0.04250618	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:07:25.901264+00
1692	aave:DAI	0.03557108	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	ethereum	DAI	0.0362113	\N	\N	llama	2025-09-12 03:07:25.901264+00
1685	aave:USDT	0.04722667	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:07:25.903549+00
1686	aave:USDC	0.02408758	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:07:25.907611+00
1993	aave:DAI	0.03617090	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	ethereum	DAI	0.0378776	\N	\N	llama	2025-09-15 00:11:15.190015+00
1837	aave:DAI	0.03720378	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:42:14.183323+00
1833	aave:USDC	0.04423265	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.196131+00
1689	aave:USDT	0.04445851	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:07:25.903549+00
1693	aave:USDT	0.03374488	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	avalanche	USDT	0.0343207	\N	\N	llama	2025-09-12 03:07:25.903549+00
1690	aave:USDC	0.04618592	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:07:25.907611+00
1691	aave:USDC	0.04907527	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:07:25.907611+00
1694	aave:USDC	0.04737011	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:07:25.907611+00
1695	aave:USDC	0.03718904	2025-09-12 03:07:23.904+00	2025-09-12 03:07:25.855759+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:07:25.907611+00
1696	justlend:USDD	0.00001475	2025-09-12 03:07:24.203+00	2025-09-12 03:07:25.855759+00	justlend	tron	USDD	1.4752355001146356e-05	\N	0	justlend	2025-09-12 03:07:25.909359+00
1697	justlend:USDT	0.01474159	2025-09-12 03:07:24.203+00	2025-09-12 03:07:25.855759+00	justlend	tron	USDT	0.014850485042984252	\N	0	justlend	2025-09-12 03:07:25.91198+00
1698	stride:stATOM	0.15140000	2025-09-12 03:07:23.927+00	2025-09-12 03:07:25.855759+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:07:25.914325+00
1699	stride:stTIA	0.11000000	2025-09-12 03:07:23.927+00	2025-09-12 03:07:25.855759+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:07:25.916599+00
1700	stride:stJUNO	0.22620000	2025-09-12 03:07:23.927+00	2025-09-12 03:07:25.855759+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:07:25.918781+00
1701	stride:stLUNA	0.17720000	2025-09-12 03:07:23.927+00	2025-09-12 03:07:25.855759+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:07:25.922504+00
1702	stride:stBAND	0.15430000	2025-09-12 03:07:23.927+00	2025-09-12 03:07:25.855759+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:07:25.925035+00
1706	aave:AUSD	0.04842689	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	avalanche	AUSD	0.049615259575344295	\N	\N	onchain	2025-09-12 03:37:55.601263+00
1705	aave:DAI	0.03596263	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	ethereum	DAI	0.036210900000000004	\N	\N	llama	2025-09-12 03:37:55.700505+00
1710	aave:DAI	0.03557069	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	ethereum	DAI	0.036210900000000004	\N	\N	llama	2025-09-12 03:37:55.700505+00
1724	aave:AUSD	0.04842689	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	avalanche	AUSD	0.049615259575344295	\N	\N	onchain	2025-09-12 03:37:55.701921+00
1703	aave:USDT	0.04743807	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.702985+00
1707	aave:USDT	0.04447362	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.702985+00
1711	aave:USDT	0.03323379	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.702985+00
1704	aave:USDC	0.02408765	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.768338+00
1708	aave:USDC	0.04623423	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.768338+00
1709	aave:USDC	0.04882102	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.768338+00
1712	aave:USDC	0.04645601	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.768338+00
1713	aave:USDC	0.03718904	2025-09-12 03:37:53.933+00	2025-09-12 03:37:55.582779+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.768338+00
1714	justlend:USDD	0.00001477	2025-09-12 03:37:54.174+00	2025-09-12 03:37:55.582779+00	justlend	tron	USDD	1.4767566072215743e-05	\N	0	justlend	2025-09-12 03:37:55.775036+00
1715	justlend:USDT	0.01466939	2025-09-12 03:37:54.174+00	2025-09-12 03:37:55.582779+00	justlend	tron	USDT	0.014777214871454447	\N	0	justlend	2025-09-12 03:37:55.778342+00
1723	aave:DAI	0.03596263	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	ethereum	DAI	0.036210900000000004	\N	\N	llama	2025-09-12 03:37:55.780035+00
1728	aave:DAI	0.03557069	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	ethereum	DAI	0.036210900000000004	\N	\N	llama	2025-09-12 03:37:55.780035+00
1716	stride:stATOM	0.15140000	2025-09-12 03:37:53.935+00	2025-09-12 03:37:55.582779+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:37:55.781236+00
1721	aave:USDT	0.04743807	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.782283+00
1725	aave:USDT	0.04447362	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.782283+00
1729	aave:USDT	0.03323379	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.782283+00
1717	stride:stTIA	0.11000000	2025-09-12 03:37:53.935+00	2025-09-12 03:37:55.582779+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:37:55.784205+00
1742	aave:AUSD	0.04842689	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	avalanche	AUSD	0.049615259575344295	\N	\N	onchain	2025-09-12 03:37:55.828347+00
1722	aave:USDC	0.02408765	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.831139+00
1726	aave:USDC	0.04623423	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.831139+00
1727	aave:USDC	0.04882102	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.831139+00
1730	aave:USDC	0.04645601	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.831139+00
1732	justlend:USDD	0.00001477	2025-09-12 03:37:54.148+00	2025-09-12 03:37:55.685483+00	justlend	tron	USDD	1.4767566072215743e-05	\N	0	justlend	2025-09-12 03:37:55.833444+00
1720	stride:stBAND	0.15430000	2025-09-12 03:37:53.935+00	2025-09-12 03:37:55.582779+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:37:55.834355+00
1733	justlend:USDT	0.01466939	2025-09-12 03:37:54.148+00	2025-09-12 03:37:55.685483+00	justlend	tron	USDT	0.014777214871454447	\N	0	justlend	2025-09-12 03:37:55.835574+00
1741	aave:DAI	0.03596263	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	ethereum	DAI	0.036210900000000004	\N	\N	llama	2025-09-12 03:37:55.837465+00
1734	stride:stATOM	0.15140000	2025-09-12 03:37:53.918+00	2025-09-12 03:37:55.685483+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:37:55.837545+00
1739	aave:USDT	0.04743807	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.838931+00
1743	aave:USDT	0.04447362	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.838931+00
1735	stride:stTIA	0.11000000	2025-09-12 03:37:53.918+00	2025-09-12 03:37:55.685483+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:37:55.840033+00
1736	stride:stJUNO	0.22620000	2025-09-12 03:37:53.918+00	2025-09-12 03:37:55.685483+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:37:55.842045+00
1740	aave:USDC	0.02408765	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.843097+00
1744	aave:USDC	0.04623423	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.843097+00
1745	aave:USDC	0.04882102	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.843097+00
1737	stride:stLUNA	0.17720000	2025-09-12 03:37:53.918+00	2025-09-12 03:37:55.685483+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:37:55.844226+00
1738	stride:stBAND	0.15430000	2025-09-12 03:37:53.918+00	2025-09-12 03:37:55.685483+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:37:55.846338+00
1994	aave:AUSD	0.05115548	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	avalanche	AUSD	0.05248274452587909	\N	\N	onchain	2025-09-15 00:11:15.073116+00
1746	aave:DAI	0.03557069	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	ethereum	DAI	0.036210900000000004	\N	\N	llama	2025-09-12 03:37:55.837465+00
1747	aave:USDT	0.03323379	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	avalanche	USDT	0.0337922	\N	\N	llama	2025-09-12 03:37:55.838931+00
1748	aave:USDC	0.04645601	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.843097+00
1749	aave:USDC	0.03718904	2025-09-12 03:37:53.925+00	2025-09-12 03:37:55.768086+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.843097+00
1750	justlend:USDD	0.00001477	2025-09-12 03:37:54.146+00	2025-09-12 03:37:55.768086+00	justlend	tron	USDD	1.4767566072215743e-05	\N	0	justlend	2025-09-12 03:37:55.845218+00
1751	justlend:USDT	0.01466939	2025-09-12 03:37:54.146+00	2025-09-12 03:37:55.768086+00	justlend	tron	USDT	0.014777214871454447	\N	0	justlend	2025-09-12 03:37:55.847536+00
1752	stride:stATOM	0.15140000	2025-09-12 03:37:53.929+00	2025-09-12 03:37:55.768086+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-12 03:37:55.849665+00
1753	stride:stTIA	0.11000000	2025-09-12 03:37:53.929+00	2025-09-12 03:37:55.768086+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-12 03:37:55.851079+00
1754	stride:stJUNO	0.22620000	2025-09-12 03:37:53.929+00	2025-09-12 03:37:55.768086+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:37:55.852476+00
1755	stride:stLUNA	0.17720000	2025-09-12 03:37:53.929+00	2025-09-12 03:37:55.768086+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:37:55.853835+00
1756	stride:stBAND	0.15430000	2025-09-12 03:37:53.929+00	2025-09-12 03:37:55.768086+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-12 03:37:55.855221+00
1832	aave:AUSD	0.05146803	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	avalanche	AUSD	0.052811709710025134	\N	\N	onchain	2025-09-14 19:42:14.153341+00
1829	aave:USDT	0.04664594	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.189235+00
1834	aave:USDT	0.04749504	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.189235+00
1838	aave:USDT	0.03430393	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.189235+00
1830	aave:USDC	0.02438470	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.196131+00
1835	aave:USDC	0.04779357	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.196131+00
1836	aave:USDC	0.04439681	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.196131+00
1839	aave:USDC	0.03584705	2025-09-14 19:42:11.361+00	2025-09-14 19:42:14.072565+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.196131+00
1855	aave:DAI	0.03720378	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:42:14.199219+00
1840	justlend:USDD	0.00001495	2025-09-14 19:42:11.567+00	2025-09-14 19:42:14.072565+00	justlend	tron	USDD	1.4950687832193665e-05	\N	0	justlend	2025-09-14 19:42:14.202738+00
1852	aave:USDT	0.04749504	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.205032+00
1856	aave:USDT	0.03430393	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.205032+00
1847	aave:USDT	0.04664594	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.205032+00
1841	justlend:USDT	0.01442397	2025-09-14 19:42:11.567+00	2025-09-14 19:42:14.072565+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:42:14.207758+00
1853	aave:USDC	0.04779357	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.209681+00
1854	aave:USDC	0.04439681	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.209681+00
1857	aave:USDC	0.03584705	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.209681+00
1848	aave:USDC	0.02438470	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.209681+00
1851	aave:USDC	0.04423265	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.209681+00
1842	stride:stATOM	0.15140000	2025-09-14 19:42:11.362+00	2025-09-14 19:42:14.072565+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:42:14.211797+00
1858	justlend:USDD	0.00001495	2025-09-14 19:42:11.61+00	2025-09-14 19:42:14.147598+00	justlend	tron	USDD	1.4950687832193665e-05	\N	0	justlend	2025-09-14 19:42:14.214296+00
1843	stride:stTIA	0.11000000	2025-09-14 19:42:11.362+00	2025-09-14 19:42:14.072565+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:42:14.216006+00
1859	justlend:USDT	0.01442397	2025-09-14 19:42:11.61+00	2025-09-14 19:42:14.147598+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:42:14.219022+00
1844	stride:stJUNO	0.22620000	2025-09-14 19:42:11.362+00	2025-09-14 19:42:14.072565+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:42:14.222321+00
1860	stride:stATOM	0.15140000	2025-09-14 19:42:11.38+00	2025-09-14 19:42:14.147598+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:42:14.225869+00
1845	stride:stLUNA	0.17720000	2025-09-14 19:42:11.362+00	2025-09-14 19:42:14.072565+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:42:14.229696+00
1861	stride:stTIA	0.11000000	2025-09-14 19:42:11.38+00	2025-09-14 19:42:14.147598+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:42:14.231445+00
1846	stride:stBAND	0.15430000	2025-09-14 19:42:11.362+00	2025-09-14 19:42:14.072565+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:42:14.234488+00
1862	stride:stJUNO	0.22620000	2025-09-14 19:42:11.38+00	2025-09-14 19:42:14.147598+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:42:14.237673+00
1863	stride:stLUNA	0.17720000	2025-09-14 19:42:11.38+00	2025-09-14 19:42:14.147598+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:42:14.243313+00
1864	stride:stBAND	0.15430000	2025-09-14 19:42:11.38+00	2025-09-14 19:42:14.147598+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:42:14.246729+00
1886	aave:AUSD	0.05145207	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	avalanche	AUSD	0.05279490542517529	\N	\N	onchain	2025-09-14 19:45:03.838122+00
1885	aave:DAI	0.03613820	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:45:03.865239+00
1891	aave:DAI	0.03720378	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:45:03.865239+00
1883	aave:USDT	0.04664594	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.871381+00
1888	aave:USDT	0.04749504	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.871381+00
1884	aave:USDC	0.02438470	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.876193+00
1887	aave:USDC	0.04423265	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.876193+00
1894	justlend:USDD	0.00001495	2025-09-14 19:45:01.314+00	2025-09-14 19:45:03.712217+00	justlend	tron	USDD	1.4950687832193665e-05	\N	0	justlend	2025-09-14 19:45:03.881429+00
1895	justlend:USDT	0.01442397	2025-09-14 19:45:01.314+00	2025-09-14 19:45:03.712217+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:45:03.887814+00
1912	justlend:USDD	0.00001495	2025-09-14 19:45:01.317+00	2025-09-14 19:45:03.822514+00	justlend	tron	USDD	1.4950687832193665e-05	\N	0	justlend	2025-09-14 19:45:03.891039+00
1896	stride:stATOM	0.15140000	2025-09-14 19:45:01.002+00	2025-09-14 19:45:03.712217+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:45:03.894178+00
1913	justlend:USDT	0.01442397	2025-09-14 19:45:01.317+00	2025-09-14 19:45:03.822514+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:45:03.897152+00
1897	stride:stTIA	0.11000000	2025-09-14 19:45:01.002+00	2025-09-14 19:45:03.712217+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:45:03.900523+00
1898	stride:stJUNO	0.22620000	2025-09-14 19:45:01.002+00	2025-09-14 19:45:03.712217+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:45:03.908306+00
1899	stride:stLUNA	0.17720000	2025-09-14 19:45:01.002+00	2025-09-14 19:45:03.712217+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:45:03.915137+00
1718	stride:stJUNO	0.22620000	2025-09-12 03:37:53.935+00	2025-09-12 03:37:55.582779+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-12 03:37:55.829876+00
1719	stride:stLUNA	0.17720000	2025-09-12 03:37:53.935+00	2025-09-12 03:37:55.582779+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-12 03:37:55.832344+00
1814	aave:AUSD	0.05146803	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	avalanche	AUSD	0.052811709710025134	\N	\N	onchain	2025-09-14 19:42:14.147782+00
2210	aave:AUSD	0.04389887	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	avalanche	AUSD	0.044873924860383996	\N	\N	onchain	2025-09-16 19:11:25.540782+00
2209	aave:DAI	0.03556149	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	ethereum	DAI	0.0414968	\N	\N	llama	2025-09-16 19:11:25.556876+00
2216	aave:DAI	0.04065891	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	ethereum	DAI	0.0414968	\N	\N	llama	2025-09-16 19:11:25.556876+00
2208	aave:USDC	0.02527293	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.567649+00
1999	aave:DAI	0.03717786	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	ethereum	DAI	0.0378776	\N	\N	llama	2025-09-15 00:11:15.190015+00
1819	aave:DAI	0.03720378	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:42:14.172552+00
1811	aave:USDT	0.04664594	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:42:14.176918+00
1812	aave:USDC	0.02438470	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.183446+00
1815	aave:USDC	0.04423265	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.183446+00
1817	aave:USDC	0.04779357	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.183446+00
1818	aave:USDC	0.04439681	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.183446+00
1821	aave:USDC	0.03584705	2025-09-14 19:42:11.357+00	2025-09-14 19:42:13.988766+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:42:14.183446+00
1822	justlend:USDD	0.00001495	2025-09-14 19:42:11.562+00	2025-09-14 19:42:13.988766+00	justlend	tron	USDD	1.4950687832193665e-05	\N	0	justlend	2025-09-14 19:42:14.189745+00
1823	justlend:USDT	0.01442397	2025-09-14 19:42:11.562+00	2025-09-14 19:42:13.988766+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:42:14.19584+00
1824	stride:stATOM	0.15140000	2025-09-14 19:42:11.36+00	2025-09-14 19:42:13.988766+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:42:14.202874+00
1825	stride:stTIA	0.11000000	2025-09-14 19:42:11.36+00	2025-09-14 19:42:13.988766+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:42:14.207625+00
1826	stride:stJUNO	0.22620000	2025-09-14 19:42:11.36+00	2025-09-14 19:42:13.988766+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:42:14.212045+00
1827	stride:stLUNA	0.17720000	2025-09-14 19:42:11.36+00	2025-09-14 19:42:13.988766+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:42:14.21606+00
1991	aave:USDT	0.04690715	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.19505+00
1992	aave:USDC	0.02390799	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.201076+00
1995	aave:USDC	0.04423265	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.201076+00
1997	aave:USDC	0.04765600	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.201076+00
1998	aave:USDC	0.04449974	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.201076+00
2001	aave:USDC	0.03582756	2025-09-15 00:11:12.942+00	2025-09-15 00:11:15.046607+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.201076+00
2002	justlend:USDD	0.00001495	2025-09-15 00:11:13.193+00	2025-09-15 00:11:15.046607+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:11:15.207436+00
2003	justlend:USDT	0.01455455	2025-09-15 00:11:13.193+00	2025-09-15 00:11:15.046607+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:11:15.214635+00
2004	stride:stATOM	0.15140000	2025-09-15 00:11:12.944+00	2025-09-15 00:11:15.046607+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:11:15.219783+00
2005	stride:stTIA	0.11000000	2025-09-15 00:11:12.944+00	2025-09-15 00:11:15.046607+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:11:15.223936+00
2006	stride:stJUNO	0.22620000	2025-09-15 00:11:12.944+00	2025-09-15 00:11:15.046607+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:11:15.289451+00
1868	aave:AUSD	0.05145207	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	avalanche	AUSD	0.05279490542517529	\N	\N	onchain	2025-09-14 19:45:03.828538+00
1904	aave:AUSD	0.05145207	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	avalanche	AUSD	0.05279490542517529	\N	\N	onchain	2025-09-14 19:45:03.846107+00
1867	aave:DAI	0.03613820	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:45:03.858539+00
1873	aave:DAI	0.03720378	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:45:03.858539+00
1865	aave:USDT	0.04664594	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.863339+00
1870	aave:USDT	0.04749504	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.863339+00
1874	aave:USDT	0.03430393	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.863339+00
1866	aave:USDC	0.02438470	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.868588+00
1869	aave:USDC	0.04423265	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.868588+00
1871	aave:USDC	0.04779357	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.868588+00
1872	aave:USDC	0.04439681	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.868588+00
1875	aave:USDC	0.03584705	2025-09-14 19:45:01.004+00	2025-09-14 19:45:03.62406+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.868588+00
1876	justlend:USDD	0.00001495	2025-09-14 19:45:01.309+00	2025-09-14 19:45:03.62406+00	justlend	tron	USDD	1.4950687832193665e-05	\N	0	justlend	2025-09-14 19:45:03.873491+00
1903	aave:DAI	0.03613820	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:45:03.874113+00
1909	aave:DAI	0.03720378	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:45:03.874113+00
1877	justlend:USDT	0.01442397	2025-09-14 19:45:01.309+00	2025-09-14 19:45:03.62406+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:45:03.879048+00
1901	aave:USDT	0.04664594	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.879327+00
1906	aave:USDT	0.04749504	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.879327+00
1910	aave:USDT	0.03430393	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.879327+00
1878	stride:stATOM	0.15140000	2025-09-14 19:45:01.005+00	2025-09-14 19:45:03.62406+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:45:03.883623+00
1902	aave:USDC	0.02438470	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.884771+00
1905	aave:USDC	0.04423265	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.884771+00
1879	stride:stTIA	0.11000000	2025-09-14 19:45:01.005+00	2025-09-14 19:45:03.62406+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:45:03.891191+00
1880	stride:stJUNO	0.22620000	2025-09-14 19:45:01.005+00	2025-09-14 19:45:03.62406+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:45:03.897058+00
1881	stride:stLUNA	0.17720000	2025-09-14 19:45:01.005+00	2025-09-14 19:45:03.62406+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:45:03.904153+00
1882	stride:stBAND	0.15430000	2025-09-14 19:45:01.005+00	2025-09-14 19:45:03.62406+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:45:03.911212+00
1731	aave:USDC	0.03718904	2025-09-12 03:37:53.892+00	2025-09-12 03:37:55.685483+00	aave	celo	USDC	0.0378892	\N	\N	llama	2025-09-12 03:37:55.831139+00
1850	aave:AUSD	0.05146803	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	avalanche	AUSD	0.052811709710025134	\N	\N	onchain	2025-09-14 19:42:14.169566+00
1849	aave:DAI	0.03613820	2025-09-14 19:42:11.378+00	2025-09-14 19:42:14.147598+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:42:14.199219+00
1760	aave:AUSD	0.05090159	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	avalanche	AUSD	0.05221560075087872	\N	\N	onchain	2025-09-13 02:10:25.070317+00
1759	aave:DAI	0.03603760	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	ethereum	DAI	0.0379626	\N	\N	llama	2025-09-13 02:10:25.08879+00
1764	aave:DAI	0.03725975	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	ethereum	DAI	0.0379626	\N	\N	llama	2025-09-13 02:10:25.08879+00
1757	aave:USDT	0.04916377	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.094871+00
1761	aave:USDT	0.04538504	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.094871+00
1765	aave:USDT	0.03567366	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.094871+00
1758	aave:USDC	0.02430566	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.106845+00
1762	aave:USDC	0.04678387	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.106845+00
1763	aave:USDC	0.04863587	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.106845+00
1766	aave:USDC	0.04732948	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.106845+00
1767	aave:USDC	0.03719250	2025-09-13 02:10:21.97+00	2025-09-13 02:10:24.998853+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.106845+00
1768	justlend:USDD	0.00001493	2025-09-13 02:10:22.238+00	2025-09-13 02:10:24.998853+00	justlend	tron	USDD	1.4932228456387975e-05	\N	0	justlend	2025-09-13 02:10:25.11153+00
1769	justlend:USDT	0.01521206	2025-09-13 02:10:22.238+00	2025-09-13 02:10:24.998853+00	justlend	tron	USDT	0.01532802627056129	\N	0	justlend	2025-09-13 02:10:25.1176+00
1770	stride:stATOM	0.15140000	2025-09-13 02:10:21.972+00	2025-09-13 02:10:24.998853+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-13 02:10:25.121779+00
1771	stride:stTIA	0.11000000	2025-09-13 02:10:21.972+00	2025-09-13 02:10:24.998853+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-13 02:10:25.125157+00
1772	stride:stJUNO	0.22620000	2025-09-13 02:10:21.972+00	2025-09-13 02:10:24.998853+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-13 02:10:25.128474+00
1773	stride:stLUNA	0.17720000	2025-09-13 02:10:21.972+00	2025-09-13 02:10:24.998853+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-13 02:10:25.13122+00
1774	stride:stBAND	0.15430000	2025-09-13 02:10:21.972+00	2025-09-13 02:10:24.998853+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-13 02:10:25.133737+00
1778	aave:AUSD	0.05090159	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	avalanche	AUSD	0.05221560075087872	\N	\N	onchain	2025-09-13 02:10:25.26758+00
1777	aave:DAI	0.03603760	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	ethereum	DAI	0.0379626	\N	\N	llama	2025-09-13 02:10:25.286641+00
1782	aave:DAI	0.03725975	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	ethereum	DAI	0.0379626	\N	\N	llama	2025-09-13 02:10:25.286641+00
1775	aave:USDT	0.04916377	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.291744+00
1779	aave:USDT	0.04538504	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.291744+00
1783	aave:USDT	0.03567366	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.291744+00
1776	aave:USDC	0.02430566	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.299588+00
1780	aave:USDC	0.04678387	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.299588+00
1781	aave:USDC	0.04863587	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.299588+00
1784	aave:USDC	0.04732948	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.299588+00
1785	aave:USDC	0.03719250	2025-09-13 02:10:21.98+00	2025-09-13 02:10:25.249742+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.299588+00
1786	justlend:USDD	0.00001493	2025-09-13 02:10:22.247+00	2025-09-13 02:10:25.249742+00	justlend	tron	USDD	1.4932228456387975e-05	\N	0	justlend	2025-09-13 02:10:25.302794+00
1787	justlend:USDT	0.01521206	2025-09-13 02:10:22.247+00	2025-09-13 02:10:25.249742+00	justlend	tron	USDT	0.01532802627056129	\N	0	justlend	2025-09-13 02:10:25.306953+00
1788	stride:stATOM	0.15140000	2025-09-13 02:10:21.984+00	2025-09-13 02:10:25.249742+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-13 02:10:25.311149+00
1789	stride:stTIA	0.11000000	2025-09-13 02:10:21.984+00	2025-09-13 02:10:25.249742+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-13 02:10:25.315122+00
1790	stride:stJUNO	0.22620000	2025-09-13 02:10:21.984+00	2025-09-13 02:10:25.249742+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-13 02:10:25.318789+00
1791	stride:stLUNA	0.17720000	2025-09-13 02:10:21.984+00	2025-09-13 02:10:25.249742+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-13 02:10:25.323009+00
1792	stride:stBAND	0.15430000	2025-09-13 02:10:21.984+00	2025-09-13 02:10:25.249742+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-13 02:10:25.326979+00
1796	aave:AUSD	0.05090159	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	avalanche	AUSD	0.05221560075087872	\N	\N	onchain	2025-09-13 02:10:25.624512+00
1795	aave:DAI	0.03603760	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	ethereum	DAI	0.0379626	\N	\N	llama	2025-09-13 02:10:25.639333+00
1800	aave:DAI	0.03725975	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	ethereum	DAI	0.0379626	\N	\N	llama	2025-09-13 02:10:25.639333+00
1793	aave:USDT	0.04916377	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.643296+00
1797	aave:USDT	0.04538504	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.643296+00
1801	aave:USDT	0.03567366	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	avalanche	USDT	0.0363176	\N	\N	llama	2025-09-13 02:10:25.643296+00
1794	aave:USDC	0.02430566	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.651753+00
1798	aave:USDC	0.04678387	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.651753+00
1799	aave:USDC	0.04863587	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.651753+00
1802	aave:USDC	0.04732948	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.651753+00
1803	aave:USDC	0.03719250	2025-09-13 02:10:21.989+00	2025-09-13 02:10:25.585578+00	aave	celo	USDC	0.037892800000000004	\N	\N	llama	2025-09-13 02:10:25.651753+00
1804	justlend:USDD	0.00001493	2025-09-13 02:10:22.294+00	2025-09-13 02:10:25.585578+00	justlend	tron	USDD	1.4932228456387975e-05	\N	0	justlend	2025-09-13 02:10:25.656081+00
1805	justlend:USDT	0.01521206	2025-09-13 02:10:22.294+00	2025-09-13 02:10:25.585578+00	justlend	tron	USDT	0.01532802627056129	\N	0	justlend	2025-09-13 02:10:25.660739+00
1806	stride:stATOM	0.15140000	2025-09-13 02:10:21.991+00	2025-09-13 02:10:25.585578+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-13 02:10:25.664722+00
1807	stride:stTIA	0.11000000	2025-09-13 02:10:21.991+00	2025-09-13 02:10:25.585578+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-13 02:10:25.668905+00
1808	stride:stJUNO	0.22620000	2025-09-13 02:10:21.991+00	2025-09-13 02:10:25.585578+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-13 02:10:25.672674+00
1809	stride:stLUNA	0.17720000	2025-09-13 02:10:21.991+00	2025-09-13 02:10:25.585578+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-13 02:10:25.676219+00
1810	stride:stBAND	0.15430000	2025-09-13 02:10:21.991+00	2025-09-13 02:10:25.585578+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-13 02:10:25.679519+00
2246	aave:AUSD	0.04389887	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	avalanche	AUSD	0.044873924860383996	\N	\N	onchain	2025-09-16 19:11:25.843764+00
1907	aave:USDC	0.04779357	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.884771+00
1908	aave:USDC	0.04439681	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.884771+00
1911	aave:USDC	0.03584705	2025-09-14 19:45:01.017+00	2025-09-14 19:45:03.822514+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.884771+00
1914	stride:stATOM	0.15140000	2025-09-14 19:45:01.018+00	2025-09-14 19:45:03.822514+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:45:03.904093+00
1915	stride:stTIA	0.11000000	2025-09-14 19:45:01.018+00	2025-09-14 19:45:03.822514+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:45:03.911215+00
1916	stride:stJUNO	0.22620000	2025-09-14 19:45:01.018+00	2025-09-14 19:45:03.822514+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:45:03.918906+00
1917	stride:stLUNA	0.17720000	2025-09-14 19:45:01.018+00	2025-09-14 19:45:03.822514+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:45:03.92545+00
1918	stride:stBAND	0.15430000	2025-09-14 19:45:01.018+00	2025-09-14 19:45:03.822514+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:45:03.931675+00
2012	aave:AUSD	0.05115548	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	avalanche	AUSD	0.05248274452587909	\N	\N	onchain	2025-09-15 00:11:15.204478+00
2011	aave:DAI	0.03617090	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	ethereum	DAI	0.0378776	\N	\N	llama	2025-09-15 00:11:15.28973+00
2017	aave:DAI	0.03717786	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	ethereum	DAI	0.0378776	\N	\N	llama	2025-09-15 00:11:15.28973+00
2009	aave:USDT	0.04690715	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.299619+00
2014	aave:USDT	0.04704540	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.299619+00
2018	aave:USDT	0.03455881	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.299619+00
2010	aave:USDC	0.02390799	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.308224+00
2013	aave:USDC	0.04423265	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.308224+00
2015	aave:USDC	0.04765600	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.308224+00
2016	aave:USDC	0.04449974	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.308224+00
2019	aave:USDC	0.03582756	2025-09-15 00:11:12.938+00	2025-09-15 00:11:15.175887+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.308224+00
2020	justlend:USDD	0.00001495	2025-09-15 00:11:13.19+00	2025-09-15 00:11:15.175887+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:11:15.316521+00
2021	justlend:USDT	0.01455455	2025-09-15 00:11:13.19+00	2025-09-15 00:11:15.175887+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:11:15.322312+00
2022	stride:stATOM	0.15140000	2025-09-15 00:11:12.941+00	2025-09-15 00:11:15.175887+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:11:15.331061+00
2023	stride:stTIA	0.11000000	2025-09-15 00:11:12.941+00	2025-09-15 00:11:15.175887+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:11:15.338157+00
2024	stride:stJUNO	0.22620000	2025-09-15 00:11:12.941+00	2025-09-15 00:11:15.175887+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:11:15.345208+00
2025	stride:stLUNA	0.17720000	2025-09-15 00:11:12.941+00	2025-09-15 00:11:15.175887+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:11:15.351516+00
2026	stride:stBAND	0.15430000	2025-09-15 00:11:12.941+00	2025-09-15 00:11:15.175887+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:11:15.357969+00
2066	aave:AUSD	0.05115899	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	avalanche	AUSD	0.05248644053603968	\N	\N	onchain	2025-09-15 00:26:15.908239+00
2065	aave:DAI	0.03617090	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:26:15.946647+00
2071	aave:DAI	0.03717796	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:26:15.946647+00
2063	aave:USDT	0.04691873	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:15.954078+00
2068	aave:USDT	0.04717677	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:15.954078+00
2072	aave:USDT	0.03447408	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:15.954078+00
2064	aave:USDC	0.02346841	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.963215+00
2067	aave:USDC	0.04423265	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.963215+00
2069	aave:USDC	0.04808087	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.963215+00
2070	aave:USDC	0.04455425	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.963215+00
2073	aave:USDC	0.03582756	2025-09-15 00:26:12.918+00	2025-09-15 00:26:15.860413+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.963215+00
2074	justlend:USDD	0.00001495	2025-09-15 00:26:14.054+00	2025-09-15 00:26:15.860413+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:26:15.971821+00
2075	justlend:USDT	0.01455455	2025-09-15 00:26:14.054+00	2025-09-15 00:26:15.860413+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:26:16.033549+00
2076	stride:stATOM	0.15140000	2025-09-15 00:26:12.919+00	2025-09-15 00:26:15.860413+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:26:16.037831+00
2077	stride:stTIA	0.11000000	2025-09-15 00:26:12.919+00	2025-09-15 00:26:15.860413+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:26:16.045813+00
2078	stride:stJUNO	0.22620000	2025-09-15 00:26:12.919+00	2025-09-15 00:26:15.860413+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:26:16.051303+00
2079	stride:stLUNA	0.17720000	2025-09-15 00:26:12.919+00	2025-09-15 00:26:15.860413+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:26:16.059417+00
2080	stride:stBAND	0.15430000	2025-09-15 00:26:12.919+00	2025-09-15 00:26:15.860413+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:26:16.065997+00
2127	aave:USDC	0.03582756	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.877846+00
2128	justlend:USDD	0.00001495	2025-09-15 00:33:05.287+00	2025-09-15 00:33:07.746428+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:33:07.882234+00
2129	justlend:USDT	0.01455455	2025-09-15 00:33:05.287+00	2025-09-15 00:33:07.746428+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:33:07.88805+00
2130	stride:stATOM	0.15140000	2025-09-15 00:33:05.068+00	2025-09-15 00:33:07.746428+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:33:07.893974+00
2131	stride:stTIA	0.11000000	2025-09-15 00:33:05.068+00	2025-09-15 00:33:07.746428+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:33:07.897942+00
2132	stride:stJUNO	0.22620000	2025-09-15 00:33:05.068+00	2025-09-15 00:33:07.746428+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:33:07.903306+00
2133	stride:stLUNA	0.17720000	2025-09-15 00:33:05.068+00	2025-09-15 00:33:07.746428+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:33:07.910031+00
2134	stride:stBAND	0.15430000	2025-09-15 00:33:05.068+00	2025-09-15 00:33:07.746428+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:33:07.914127+00
2156	aave:AUSD	0.04885002	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	avalanche	AUSD	0.0500594187063097	\N	\N	onchain	2025-09-16 02:07:04.436775+00
2155	aave:DAI	0.03556960	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	ethereum	DAI	0.040965100000000004	\N	\N	llama	2025-09-16 02:07:04.636459+00
2154	aave:USDC	0.02422606	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.643253+00
2158	aave:USDC	0.04777765	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.643253+00
1892	aave:USDT	0.03430393	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:45:03.871381+00
1889	aave:USDC	0.04779357	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.876193+00
1890	aave:USDC	0.04439681	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.876193+00
1893	aave:USDC	0.03584705	2025-09-14 19:45:01.001+00	2025-09-14 19:45:03.712217+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:45:03.876193+00
1900	stride:stBAND	0.15430000	2025-09-14 19:45:01.002+00	2025-09-14 19:45:03.712217+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:45:03.921978+00
2030	aave:AUSD	0.05115548	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	avalanche	AUSD	0.05248274452587909	\N	\N	onchain	2025-09-15 00:11:15.321976+00
2029	aave:DAI	0.03617090	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	ethereum	DAI	0.0378776	\N	\N	llama	2025-09-15 00:11:15.354888+00
2035	aave:DAI	0.03717786	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	ethereum	DAI	0.0378776	\N	\N	llama	2025-09-15 00:11:15.354888+00
2028	aave:USDC	0.02390799	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.366419+00
2031	aave:USDC	0.04423265	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.366419+00
2038	justlend:USDD	0.00001495	2025-09-15 00:11:13.219+00	2025-09-15 00:11:15.289703+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:11:15.370635+00
1922	aave:AUSD	0.05124333	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	avalanche	AUSD	0.05257520019301487	\N	\N	onchain	2025-09-14 19:56:57.192188+00
1940	aave:AUSD	0.05124333	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	avalanche	AUSD	0.05257520019301487	\N	\N	onchain	2025-09-14 19:56:57.194533+00
1939	aave:DAI	0.03614304	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:56:57.281137+00
1945	aave:DAI	0.03720378	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:56:57.281137+00
1921	aave:DAI	0.03614304	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:56:57.284576+00
1927	aave:DAI	0.03720378	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:56:57.284576+00
1937	aave:USDT	0.04673340	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.288572+00
1942	aave:USDT	0.04749504	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.288572+00
1946	aave:USDT	0.03430393	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.288572+00
1919	aave:USDT	0.04673340	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.291462+00
1924	aave:USDT	0.04749504	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.291462+00
1928	aave:USDT	0.03430393	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.291462+00
1958	aave:AUSD	0.05124333	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	avalanche	AUSD	0.05257520019301487	\N	\N	onchain	2025-09-14 19:56:57.293922+00
1938	aave:USDC	0.02437126	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.29411+00
1941	aave:USDC	0.04423265	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.29411+00
1943	aave:USDC	0.04779357	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.29411+00
1944	aave:USDC	0.04439681	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.29411+00
1947	aave:USDC	0.03584705	2025-09-14 19:56:54.679+00	2025-09-14 19:56:57.163873+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.29411+00
1920	aave:USDC	0.02437126	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.296683+00
1923	aave:USDC	0.04423265	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.296683+00
1925	aave:USDC	0.04779357	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.296683+00
1930	justlend:USDD	0.00001495	2025-09-14 19:56:54.904+00	2025-09-14 19:56:57.068649+00	justlend	tron	USDD	1.4950719359640985e-05	\N	0	justlend	2025-09-14 19:56:57.301559+00
1949	justlend:USDT	0.01442397	2025-09-14 19:56:55.174+00	2025-09-14 19:56:57.163873+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:56:57.303233+00
1931	justlend:USDT	0.01442397	2025-09-14 19:56:54.904+00	2025-09-14 19:56:57.068649+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:56:57.305721+00
1950	stride:stATOM	0.15140000	2025-09-14 19:56:54.68+00	2025-09-14 19:56:57.163873+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:56:57.309335+00
1932	stride:stATOM	0.15140000	2025-09-14 19:56:54.677+00	2025-09-14 19:56:57.068649+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:56:57.311856+00
1951	stride:stTIA	0.11000000	2025-09-14 19:56:54.68+00	2025-09-14 19:56:57.163873+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:56:57.31474+00
1933	stride:stTIA	0.11000000	2025-09-14 19:56:54.677+00	2025-09-14 19:56:57.068649+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:56:57.316775+00
1957	aave:DAI	0.03614304	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:56:57.319087+00
1963	aave:DAI	0.03720378	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:56:57.319087+00
1952	stride:stJUNO	0.22620000	2025-09-14 19:56:54.68+00	2025-09-14 19:56:57.163873+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:56:57.319248+00
1934	stride:stJUNO	0.22620000	2025-09-14 19:56:54.677+00	2025-09-14 19:56:57.068649+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:56:57.32132+00
1955	aave:USDT	0.04673340	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.32344+00
1960	aave:USDT	0.04749504	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.32344+00
1953	stride:stLUNA	0.17720000	2025-09-14 19:56:54.68+00	2025-09-14 19:56:57.163873+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:56:57.323656+00
1935	stride:stLUNA	0.17720000	2025-09-14 19:56:54.677+00	2025-09-14 19:56:57.068649+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:56:57.325572+00
1954	stride:stBAND	0.15430000	2025-09-14 19:56:54.68+00	2025-09-14 19:56:57.163873+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:56:57.328767+00
1936	stride:stBAND	0.15430000	2025-09-14 19:56:54.677+00	2025-09-14 19:56:57.068649+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:56:57.331999+00
1966	justlend:USDD	0.00001495	2025-09-14 19:56:54.939+00	2025-09-14 19:56:57.269742+00	justlend	tron	USDD	1.4950719359640985e-05	\N	0	justlend	2025-09-14 19:56:57.334883+00
1967	justlend:USDT	0.01442397	2025-09-14 19:56:54.939+00	2025-09-14 19:56:57.269742+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:56:57.34124+00
1968	stride:stATOM	0.15140000	2025-09-14 19:56:54.704+00	2025-09-14 19:56:57.269742+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:56:57.345771+00
1969	stride:stTIA	0.11000000	2025-09-14 19:56:54.704+00	2025-09-14 19:56:57.269742+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:56:57.350238+00
1970	stride:stJUNO	0.22620000	2025-09-14 19:56:54.704+00	2025-09-14 19:56:57.269742+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:56:57.354918+00
1971	stride:stLUNA	0.17720000	2025-09-14 19:56:54.704+00	2025-09-14 19:56:57.269742+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:56:57.359496+00
1972	stride:stBAND	0.15430000	2025-09-14 19:56:54.704+00	2025-09-14 19:56:57.269742+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:56:57.363619+00
2207	aave:USDT	0.04951427	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.550662+00
2214	aave:USDT	0.03109442	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.550662+00
1964	aave:USDT	0.03430393	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:56:57.32344+00
1956	aave:USDC	0.02437126	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.328251+00
1959	aave:USDC	0.04423265	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.328251+00
1961	aave:USDC	0.04779357	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.328251+00
1962	aave:USDC	0.04439681	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.328251+00
1965	aave:USDC	0.03584705	2025-09-14 19:56:54.703+00	2025-09-14 19:56:57.269742+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.328251+00
2027	aave:USDT	0.04690715	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.360776+00
2032	aave:USDT	0.04704540	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.360776+00
2036	aave:USDT	0.03455881	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	avalanche	USDT	0.035162900000000004	\N	\N	llama	2025-09-15 00:11:15.360776+00
2033	aave:USDC	0.04765600	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.366419+00
2034	aave:USDC	0.04449974	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.366419+00
2037	aave:USDC	0.03582756	2025-09-15 00:11:12.952+00	2025-09-15 00:11:15.289703+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:11:15.366419+00
2039	justlend:USDT	0.01455455	2025-09-15 00:11:13.219+00	2025-09-15 00:11:15.289703+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:11:15.375748+00
2040	stride:stATOM	0.15140000	2025-09-15 00:11:12.955+00	2025-09-15 00:11:15.289703+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:11:15.380488+00
2041	stride:stTIA	0.11000000	2025-09-15 00:11:12.955+00	2025-09-15 00:11:15.289703+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:11:15.385628+00
2042	stride:stJUNO	0.22620000	2025-09-15 00:11:12.955+00	2025-09-15 00:11:15.289703+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:11:15.390624+00
2043	stride:stLUNA	0.17720000	2025-09-15 00:11:12.955+00	2025-09-15 00:11:15.289703+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:11:15.396336+00
2044	stride:stBAND	0.15430000	2025-09-15 00:11:12.955+00	2025-09-15 00:11:15.289703+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:11:15.401315+00
2084	aave:AUSD	0.05115899	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	avalanche	AUSD	0.05248644053603968	\N	\N	onchain	2025-09-15 00:26:16.066038+00
2083	aave:DAI	0.03617090	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:26:16.093955+00
2089	aave:DAI	0.03717796	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:26:16.093955+00
2081	aave:USDT	0.04691873	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:16.100316+00
2086	aave:USDT	0.04717677	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:16.100316+00
2090	aave:USDT	0.03447408	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:16.100316+00
2082	aave:USDC	0.02346841	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:16.107115+00
2085	aave:USDC	0.04423265	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:16.107115+00
2087	aave:USDC	0.04808087	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:16.107115+00
2088	aave:USDC	0.04455425	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:16.107115+00
2091	aave:USDC	0.03582756	2025-09-15 00:26:12.898+00	2025-09-15 00:26:16.040679+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:16.107115+00
2092	justlend:USDD	0.00001495	2025-09-15 00:26:13.162+00	2025-09-15 00:26:16.040679+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:26:16.114476+00
2093	justlend:USDT	0.01455455	2025-09-15 00:26:13.162+00	2025-09-15 00:26:16.040679+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:26:16.122011+00
2094	stride:stATOM	0.15140000	2025-09-15 00:26:12.9+00	2025-09-15 00:26:16.040679+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:26:16.127533+00
2095	stride:stTIA	0.11000000	2025-09-15 00:26:12.9+00	2025-09-15 00:26:16.040679+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:26:16.132905+00
2096	stride:stJUNO	0.22620000	2025-09-15 00:26:12.9+00	2025-09-15 00:26:16.040679+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:26:16.13807+00
2097	stride:stLUNA	0.17720000	2025-09-15 00:26:12.9+00	2025-09-15 00:26:16.040679+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:26:16.143922+00
2098	stride:stBAND	0.15430000	2025-09-15 00:26:12.9+00	2025-09-15 00:26:16.040679+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:26:16.150482+00
2138	aave:AUSD	0.05114467	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	avalanche	AUSD	0.05247137013981873	\N	\N	onchain	2025-09-15 00:33:07.845133+00
2137	aave:DAI	0.03617090	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:33:07.872061+00
2143	aave:DAI	0.03717796	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:33:07.872061+00
2135	aave:USDT	0.04691708	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.87759+00
2140	aave:USDT	0.04717677	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.87759+00
2144	aave:USDT	0.03447408	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.87759+00
2136	aave:USDC	0.02346842	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.882256+00
2139	aave:USDC	0.04423265	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.882256+00
2141	aave:USDC	0.04808087	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.882256+00
2142	aave:USDC	0.04455425	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.882256+00
2145	aave:USDC	0.03582756	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.882256+00
2146	justlend:USDD	0.00001495	2025-09-15 00:33:05.314+00	2025-09-15 00:33:07.827557+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:33:07.887989+00
2147	justlend:USDT	0.01455455	2025-09-15 00:33:05.314+00	2025-09-15 00:33:07.827557+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:33:07.893929+00
2148	stride:stATOM	0.15140000	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:33:07.898409+00
2149	stride:stTIA	0.11000000	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:33:07.903256+00
2150	stride:stJUNO	0.22620000	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:33:07.910041+00
2151	stride:stLUNA	0.17720000	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:33:07.914258+00
2007	stride:stLUNA	0.17720000	2025-09-15 00:11:12.944+00	2025-09-15 00:11:15.046607+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:11:15.297087+00
1926	aave:USDC	0.04439681	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.296683+00
1929	aave:USDC	0.03584705	2025-09-14 19:56:54.675+00	2025-09-14 19:56:57.068649+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:56:57.296683+00
2008	stride:stBAND	0.15430000	2025-09-15 00:11:12.944+00	2025-09-15 00:11:15.046607+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:11:15.303217+00
2102	aave:AUSD	0.05114467	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	avalanche	AUSD	0.05247137013981873	\N	\N	onchain	2025-09-15 00:33:07.840216+00
2101	aave:DAI	0.03617090	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:33:07.864691+00
2107	aave:DAI	0.03717796	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:33:07.864691+00
2099	aave:USDT	0.04691708	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.870522+00
2104	aave:USDT	0.04717677	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.870522+00
2108	aave:USDT	0.03447408	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.870522+00
2100	aave:USDC	0.02346842	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.875245+00
2103	aave:USDC	0.04423265	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.875245+00
2105	aave:USDC	0.04808087	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.875245+00
2106	aave:USDC	0.04455425	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.875245+00
2109	aave:USDC	0.03582756	2025-09-15 00:33:05.076+00	2025-09-15 00:33:07.631422+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.875245+00
2110	justlend:USDD	0.00001495	2025-09-15 00:33:05.314+00	2025-09-15 00:33:07.631422+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:33:07.887989+00
2112	stride:stATOM	0.15140000	2025-09-15 00:33:05.077+00	2025-09-15 00:33:07.631422+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:33:07.892234+00
2111	justlend:USDT	0.01455455	2025-09-15 00:33:05.314+00	2025-09-15 00:33:07.631422+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:33:07.893929+00
2113	stride:stTIA	0.11000000	2025-09-15 00:33:05.077+00	2025-09-15 00:33:07.631422+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:33:07.895923+00
2114	stride:stJUNO	0.22620000	2025-09-15 00:33:05.077+00	2025-09-15 00:33:07.631422+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:33:07.901636+00
2115	stride:stLUNA	0.17720000	2025-09-15 00:33:05.077+00	2025-09-15 00:33:07.631422+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:33:07.907338+00
2116	stride:stBAND	0.15430000	2025-09-15 00:33:05.077+00	2025-09-15 00:33:07.631422+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:33:07.912878+00
2152	stride:stBAND	0.15430000	2025-09-15 00:33:05.069+00	2025-09-15 00:33:07.827557+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:33:07.919147+00
2153	aave:USDT	0.04586068	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.629343+00
2157	aave:USDT	0.04517793	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.629343+00
2161	aave:USDT	0.03369934	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.629343+00
2174	aave:AUSD	0.04885002	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	avalanche	AUSD	0.0500594187063097	\N	\N	onchain	2025-09-16 02:07:04.632978+00
2162	aave:DAI	0.04014826	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	ethereum	DAI	0.040965100000000004	\N	\N	llama	2025-09-16 02:07:04.636459+00
2159	aave:USDC	0.04934106	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.643253+00
2160	aave:USDC	0.04561847	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.643253+00
2163	aave:USDC	0.03194634	2025-09-16 02:07:01.497+00	2025-09-16 02:07:04.403937+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.643253+00
2164	justlend:USDD	0.00001487	2025-09-16 02:07:01.759+00	2025-09-16 02:07:04.403937+00	justlend	tron	USDD	1.4868671990964089e-05	\N	0	justlend	2025-09-16 02:07:04.650492+00
2165	justlend:USDT	0.01567973	2025-09-16 02:07:01.759+00	2025-09-16 02:07:04.403937+00	justlend	tron	USDT	0.015802956379235678	\N	0	justlend	2025-09-16 02:07:04.657578+00
2166	stride:stATOM	0.15140000	2025-09-16 02:07:01.499+00	2025-09-16 02:07:04.403937+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 02:07:04.664371+00
2171	aave:USDT	0.04586068	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.667877+00
2175	aave:USDT	0.04517793	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.667877+00
2179	aave:USDT	0.03369934	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.667877+00
2167	stride:stTIA	0.11000000	2025-09-16 02:07:01.499+00	2025-09-16 02:07:04.403937+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 02:07:04.672393+00
2173	aave:DAI	0.03556960	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	ethereum	DAI	0.040965100000000004	\N	\N	llama	2025-09-16 02:07:04.675395+00
2180	aave:DAI	0.04014826	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	ethereum	DAI	0.040965100000000004	\N	\N	llama	2025-09-16 02:07:04.675395+00
2168	stride:stJUNO	0.22620000	2025-09-16 02:07:01.499+00	2025-09-16 02:07:04.403937+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 02:07:04.679182+00
2172	aave:USDC	0.02422606	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.683209+00
2176	aave:USDC	0.04777765	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.683209+00
2177	aave:USDC	0.04934106	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.683209+00
2178	aave:USDC	0.04561847	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.683209+00
2181	aave:USDC	0.03194634	2025-09-16 02:07:01.523+00	2025-09-16 02:07:04.537905+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.683209+00
2169	stride:stLUNA	0.17720000	2025-09-16 02:07:01.499+00	2025-09-16 02:07:04.403937+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 02:07:04.686568+00
2182	justlend:USDD	0.00001487	2025-09-16 02:07:01.799+00	2025-09-16 02:07:04.537905+00	justlend	tron	USDD	1.4868671990964089e-05	\N	0	justlend	2025-09-16 02:07:04.689925+00
2170	stride:stBAND	0.15430000	2025-09-16 02:07:01.499+00	2025-09-16 02:07:04.403937+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 02:07:04.693671+00
2183	justlend:USDT	0.01567973	2025-09-16 02:07:01.799+00	2025-09-16 02:07:04.537905+00	justlend	tron	USDT	0.015802956379235678	\N	0	justlend	2025-09-16 02:07:04.696951+00
2184	stride:stATOM	0.15140000	2025-09-16 02:07:01.524+00	2025-09-16 02:07:04.537905+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 02:07:04.70422+00
2185	stride:stTIA	0.11000000	2025-09-16 02:07:01.524+00	2025-09-16 02:07:04.537905+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 02:07:04.708836+00
2186	stride:stJUNO	0.22620000	2025-09-16 02:07:01.524+00	2025-09-16 02:07:04.537905+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 02:07:04.712855+00
2187	stride:stLUNA	0.17720000	2025-09-16 02:07:01.524+00	2025-09-16 02:07:04.537905+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 02:07:04.717166+00
2188	stride:stBAND	0.15430000	2025-09-16 02:07:01.524+00	2025-09-16 02:07:04.537905+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 02:07:04.720852+00
2191	aave:DAI	0.03556960	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	ethereum	DAI	0.040965100000000004	\N	\N	llama	2025-09-16 02:07:04.878857+00
2190	aave:USDC	0.02422606	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.882618+00
1948	justlend:USDD	0.00001495	2025-09-14 19:56:55.174+00	2025-09-14 19:56:57.163873+00	justlend	tron	USDD	1.4950719359640985e-05	\N	0	justlend	2025-09-14 19:56:57.298714+00
2211	aave:USDC	0.04373828	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.567649+00
2213	aave:USDC	0.05637400	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.567649+00
2215	aave:USDC	0.04767821	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.567649+00
2217	aave:USDC	0.03194769	2025-09-16 19:11:23.743+00	2025-09-16 19:11:25.522604+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.567649+00
2218	justlend:USDD	0.00001497	2025-09-16 19:11:24.103+00	2025-09-16 19:11:25.522604+00	justlend	tron	USDD	1.496709727444312e-05	\N	0	justlend	2025-09-16 19:11:25.570698+00
2219	justlend:USDT	0.01576476	2025-09-16 19:11:24.103+00	2025-09-16 19:11:25.522604+00	justlend	tron	USDT	0.01588933369937262	\N	0	justlend	2025-09-16 19:11:25.573626+00
2220	stride:stATOM	0.15140000	2025-09-16 19:11:23.745+00	2025-09-16 19:11:25.522604+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 19:11:25.575563+00
2221	stride:stTIA	0.11000000	2025-09-16 19:11:23.745+00	2025-09-16 19:11:25.522604+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 19:11:25.578135+00
2222	stride:stJUNO	0.22620000	2025-09-16 19:11:23.745+00	2025-09-16 19:11:25.522604+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 19:11:25.581128+00
2223	stride:stLUNA	0.17720000	2025-09-16 19:11:23.745+00	2025-09-16 19:11:25.522604+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 19:11:25.584771+00
1976	aave:AUSD	0.05123800	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	avalanche	AUSD	0.05256959461243427	\N	\N	onchain	2025-09-14 19:58:54.269503+00
2048	aave:AUSD	0.05115899	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	avalanche	AUSD	0.05248644053603968	\N	\N	onchain	2025-09-15 00:26:15.895392+00
1975	aave:DAI	0.03614304	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:58:54.295761+00
1981	aave:DAI	0.03720378	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	ethereum	DAI	0.0379045	\N	\N	llama	2025-09-14 19:58:54.295761+00
1973	aave:USDT	0.04673345	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:58:54.299507+00
1978	aave:USDT	0.04749504	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:58:54.299507+00
1982	aave:USDT	0.03430393	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	avalanche	USDT	0.0348991	\N	\N	llama	2025-09-14 19:58:54.299507+00
1974	aave:USDC	0.02438497	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:58:54.30268+00
1977	aave:USDC	0.04423265	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:58:54.30268+00
1979	aave:USDC	0.04779357	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:58:54.30268+00
1980	aave:USDC	0.04439681	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:58:54.30268+00
1983	aave:USDC	0.03584705	2025-09-14 19:58:51.833+00	2025-09-14 19:58:54.246135+00	aave	celo	USDC	0.036497299999999996	\N	\N	llama	2025-09-14 19:58:54.30268+00
1984	justlend:USDD	0.00001495	2025-09-14 19:58:52.072+00	2025-09-14 19:58:54.246135+00	justlend	tron	USDD	1.4950719359640985e-05	\N	0	justlend	2025-09-14 19:58:54.305219+00
1985	justlend:USDT	0.01442397	2025-09-14 19:58:52.072+00	2025-09-14 19:58:54.246135+00	justlend	tron	USDT	0.014528210396435925	\N	0	justlend	2025-09-14 19:58:54.309359+00
1986	stride:stATOM	0.15140000	2025-09-14 19:58:51.835+00	2025-09-14 19:58:54.246135+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-14 19:58:54.314415+00
1987	stride:stTIA	0.11000000	2025-09-14 19:58:51.835+00	2025-09-14 19:58:54.246135+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-14 19:58:54.318378+00
1988	stride:stJUNO	0.22620000	2025-09-14 19:58:51.835+00	2025-09-14 19:58:54.246135+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-14 19:58:54.321897+00
1989	stride:stLUNA	0.17720000	2025-09-14 19:58:51.835+00	2025-09-14 19:58:54.246135+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-14 19:58:54.325026+00
1990	stride:stBAND	0.15430000	2025-09-14 19:58:51.835+00	2025-09-14 19:58:54.246135+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-14 19:58:54.327245+00
2047	aave:DAI	0.03617090	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:26:15.934801+00
2053	aave:DAI	0.03717796	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:26:15.934801+00
2045	aave:USDT	0.04691873	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:15.943628+00
2050	aave:USDT	0.04717677	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:15.943628+00
2054	aave:USDT	0.03447408	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:26:15.943628+00
2046	aave:USDC	0.02346841	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.950386+00
2049	aave:USDC	0.04423265	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.950386+00
2051	aave:USDC	0.04808087	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.950386+00
2052	aave:USDC	0.04455425	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.950386+00
2055	aave:USDC	0.03582756	2025-09-15 00:26:12.889+00	2025-09-15 00:26:15.753437+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:26:15.950386+00
2058	stride:stATOM	0.15140000	2025-09-15 00:26:12.894+00	2025-09-15 00:26:15.753437+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-15 00:26:16.033563+00
2059	stride:stTIA	0.11000000	2025-09-15 00:26:12.894+00	2025-09-15 00:26:15.753437+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-15 00:26:16.037892+00
2060	stride:stJUNO	0.22620000	2025-09-15 00:26:12.894+00	2025-09-15 00:26:15.753437+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-15 00:26:16.042996+00
2061	stride:stLUNA	0.17720000	2025-09-15 00:26:12.894+00	2025-09-15 00:26:15.753437+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-15 00:26:16.048556+00
2062	stride:stBAND	0.15430000	2025-09-15 00:26:12.894+00	2025-09-15 00:26:15.753437+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-15 00:26:16.053629+00
2056	justlend:USDD	0.00001495	2025-09-15 00:26:13.162+00	2025-09-15 00:26:15.753437+00	justlend	tron	USDD	1.4945431740409632e-05	\N	0	justlend	2025-09-15 00:26:16.114476+00
2057	justlend:USDT	0.01455455	2025-09-15 00:26:13.162+00	2025-09-15 00:26:15.753437+00	justlend	tron	USDT	0.014660693665265123	\N	0	justlend	2025-09-15 00:26:16.122011+00
2120	aave:AUSD	0.05114467	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	avalanche	AUSD	0.05247137013981873	\N	\N	onchain	2025-09-15 00:33:07.841498+00
2119	aave:DAI	0.03617090	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:33:07.868232+00
2125	aave:DAI	0.03717796	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	ethereum	DAI	0.0378777	\N	\N	llama	2025-09-15 00:33:07.868232+00
2117	aave:USDT	0.04691708	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.872061+00
2122	aave:USDT	0.04717677	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.872061+00
2126	aave:USDT	0.03447408	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	avalanche	USDT	0.0350752	\N	\N	llama	2025-09-15 00:33:07.872061+00
2118	aave:USDC	0.02346842	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.877846+00
2121	aave:USDC	0.04423265	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.877846+00
2123	aave:USDC	0.04808087	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.877846+00
2124	aave:USDC	0.04455425	2025-09-15 00:33:05.066+00	2025-09-15 00:33:07.746428+00	aave	celo	USDC	0.0364771	\N	\N	llama	2025-09-15 00:33:07.877846+00
2224	stride:stBAND	0.15430000	2025-09-16 19:11:23.745+00	2025-09-16 19:11:25.522604+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 19:11:25.588741+00
2192	aave:AUSD	0.04885002	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	avalanche	AUSD	0.0500594187063097	\N	\N	onchain	2025-09-16 02:07:04.857879+00
2189	aave:USDT	0.04586068	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.87461+00
2193	aave:USDT	0.04517793	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.87461+00
2197	aave:USDT	0.03369934	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	avalanche	USDT	0.0342736	\N	\N	llama	2025-09-16 02:07:04.87461+00
2198	aave:DAI	0.04014826	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	ethereum	DAI	0.040965100000000004	\N	\N	llama	2025-09-16 02:07:04.878857+00
2194	aave:USDC	0.04777765	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.882618+00
2195	aave:USDC	0.04934106	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.882618+00
2196	aave:USDC	0.04561847	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.882618+00
2199	aave:USDC	0.03194634	2025-09-16 02:07:01.493+00	2025-09-16 02:07:04.84573+00	aave	celo	USDC	0.0324621	\N	\N	llama	2025-09-16 02:07:04.882618+00
2200	justlend:USDD	0.00001487	2025-09-16 02:07:01.727+00	2025-09-16 02:07:04.84573+00	justlend	tron	USDD	1.4868671990964089e-05	\N	0	justlend	2025-09-16 02:07:04.88661+00
2201	justlend:USDT	0.01567973	2025-09-16 02:07:01.727+00	2025-09-16 02:07:04.84573+00	justlend	tron	USDT	0.015802956379235678	\N	0	justlend	2025-09-16 02:07:04.89084+00
2202	stride:stATOM	0.15140000	2025-09-16 02:07:01.495+00	2025-09-16 02:07:04.84573+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 02:07:04.893919+00
2203	stride:stTIA	0.11000000	2025-09-16 02:07:01.495+00	2025-09-16 02:07:04.84573+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 02:07:04.89735+00
2204	stride:stJUNO	0.22620000	2025-09-16 02:07:01.495+00	2025-09-16 02:07:04.84573+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 02:07:04.901805+00
2205	stride:stLUNA	0.17720000	2025-09-16 02:07:01.495+00	2025-09-16 02:07:04.84573+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 02:07:04.906159+00
2206	stride:stBAND	0.15430000	2025-09-16 02:07:01.495+00	2025-09-16 02:07:04.84573+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 02:07:04.910252+00
2228	aave:AUSD	0.04389887	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	avalanche	AUSD	0.044873924860383996	\N	\N	onchain	2025-09-16 19:11:25.837088+00
2225	aave:USDT	0.04951427	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.849271+00
2230	aave:USDT	0.09747620	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.849271+00
2232	aave:USDT	0.03109442	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.849271+00
2227	aave:DAI	0.03556149	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	ethereum	DAI	0.0414968	\N	\N	llama	2025-09-16 19:11:25.855008+00
2234	aave:DAI	0.04065891	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	ethereum	DAI	0.0414968	\N	\N	llama	2025-09-16 19:11:25.855008+00
2243	aave:USDT	0.04951427	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.856149+00
2248	aave:USDT	0.09747620	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.856149+00
2250	aave:USDT	0.03109442	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	avalanche	USDT	0.0315829	\N	\N	llama	2025-09-16 19:11:25.856149+00
2226	aave:USDC	0.02527293	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.857248+00
2229	aave:USDC	0.04373828	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.857248+00
2231	aave:USDC	0.05637400	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.857248+00
2233	aave:USDC	0.04767821	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.857248+00
2235	aave:USDC	0.03194769	2025-09-16 19:11:23.733+00	2025-09-16 19:11:25.721514+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.857248+00
2236	justlend:USDD	0.00001497	2025-09-16 19:11:24.015+00	2025-09-16 19:11:25.721514+00	justlend	tron	USDD	1.496709727444312e-05	\N	0	justlend	2025-09-16 19:11:25.859428+00
2245	aave:DAI	0.03556149	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	ethereum	DAI	0.0414968	\N	\N	llama	2025-09-16 19:11:25.860479+00
2252	aave:DAI	0.04065891	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	ethereum	DAI	0.0414968	\N	\N	llama	2025-09-16 19:11:25.860479+00
2237	justlend:USDT	0.01576476	2025-09-16 19:11:24.015+00	2025-09-16 19:11:25.721514+00	justlend	tron	USDT	0.01588933369937262	\N	0	justlend	2025-09-16 19:11:25.86165+00
2244	aave:USDC	0.02527293	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.862749+00
2247	aave:USDC	0.04373828	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.862749+00
2249	aave:USDC	0.05637400	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.862749+00
2251	aave:USDC	0.04767821	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.862749+00
2253	aave:USDC	0.03194769	2025-09-16 19:11:23.724+00	2025-09-16 19:11:25.822672+00	aave	celo	USDC	0.0324635	\N	\N	llama	2025-09-16 19:11:25.862749+00
2238	stride:stATOM	0.15140000	2025-09-16 19:11:23.734+00	2025-09-16 19:11:25.721514+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 19:11:25.863791+00
2254	justlend:USDD	0.00001497	2025-09-16 19:11:24.016+00	2025-09-16 19:11:25.822672+00	justlend	tron	USDD	1.496709727444312e-05	\N	0	justlend	2025-09-16 19:11:25.865076+00
2239	stride:stTIA	0.11000000	2025-09-16 19:11:23.734+00	2025-09-16 19:11:25.721514+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 19:11:25.866369+00
2255	justlend:USDT	0.01576476	2025-09-16 19:11:24.016+00	2025-09-16 19:11:25.822672+00	justlend	tron	USDT	0.01588933369937262	\N	0	justlend	2025-09-16 19:11:25.867229+00
2240	stride:stJUNO	0.22620000	2025-09-16 19:11:23.734+00	2025-09-16 19:11:25.721514+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 19:11:25.869149+00
2256	stride:stATOM	0.15140000	2025-09-16 19:11:23.731+00	2025-09-16 19:11:25.822672+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 19:11:25.870296+00
2241	stride:stLUNA	0.17720000	2025-09-16 19:11:23.734+00	2025-09-16 19:11:25.721514+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 19:11:25.87215+00
2257	stride:stTIA	0.11000000	2025-09-16 19:11:23.731+00	2025-09-16 19:11:25.822672+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 19:11:25.873374+00
2242	stride:stBAND	0.15430000	2025-09-16 19:11:23.734+00	2025-09-16 19:11:25.721514+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 19:11:25.874857+00
2258	stride:stJUNO	0.22620000	2025-09-16 19:11:23.731+00	2025-09-16 19:11:25.822672+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 19:11:25.875995+00
2259	stride:stLUNA	0.17720000	2025-09-16 19:11:23.731+00	2025-09-16 19:11:25.822672+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 19:11:25.878548+00
2260	stride:stBAND	0.15430000	2025-09-16 19:11:23.731+00	2025-09-16 19:11:25.822672+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 19:11:25.879992+00
2264	aave:AUSD	0.04469977	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	avalanche	AUSD	0.04571099262127798	\N	\N	onchain	2025-09-16 23:56:15.571527+00
2263	aave:DAI	0.03517348	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	ethereum	DAI	0.04136599999999999	\N	\N	llama	2025-09-16 23:56:15.600772+00
2269	aave:DAI	0.04053331	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	ethereum	DAI	0.04136599999999999	\N	\N	llama	2025-09-16 23:56:15.600772+00
2262	aave:USDC	0.02527906	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.614472+00
2265	aave:USDC	0.04458639	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.614472+00
2261	aave:USDT	0.05072927	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.595604+00
2266	aave:USDT	0.08514340	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.595604+00
2268	aave:USDT	0.03182836	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.595604+00
2267	aave:USDC	0.05559950	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.614472+00
2270	aave:USDC	0.05166565	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.614472+00
2271	aave:USDC	0.03475914	2025-09-16 23:56:12.994+00	2025-09-16 23:56:15.537839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.614472+00
2272	justlend:USDD	0.00001492	2025-09-16 23:56:13.673+00	2025-09-16 23:56:15.537839+00	justlend	tron	USDD	1.4920728142131523e-05	\N	0	justlend	2025-09-16 23:56:15.621819+00
2273	justlend:USDT	0.01576513	2025-09-16 23:56:13.673+00	2025-09-16 23:56:15.537839+00	justlend	tron	USDT	0.015889709243331662	\N	0	justlend	2025-09-16 23:56:15.625992+00
2274	stride:stATOM	0.15140000	2025-09-16 23:56:12.996+00	2025-09-16 23:56:15.537839+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 23:56:15.629303+00
2275	stride:stTIA	0.11000000	2025-09-16 23:56:12.996+00	2025-09-16 23:56:15.537839+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 23:56:15.632256+00
2276	stride:stJUNO	0.22620000	2025-09-16 23:56:12.996+00	2025-09-16 23:56:15.537839+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 23:56:15.711196+00
2277	stride:stLUNA	0.17720000	2025-09-16 23:56:12.996+00	2025-09-16 23:56:15.537839+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 23:56:15.720916+00
2278	stride:stBAND	0.15430000	2025-09-16 23:56:12.996+00	2025-09-16 23:56:15.537839+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 23:56:15.727166+00
2282	aave:AUSD	0.04469977	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	avalanche	AUSD	0.04571099262127798	\N	\N	onchain	2025-09-16 23:56:15.744194+00
2279	aave:USDT	0.05072927	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.761113+00
2284	aave:USDT	0.08514340	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.761113+00
2286	aave:USDT	0.03182836	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.761113+00
2281	aave:DAI	0.03517348	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	ethereum	DAI	0.04136599999999999	\N	\N	llama	2025-09-16 23:56:15.822822+00
2287	aave:DAI	0.04053331	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	ethereum	DAI	0.04136599999999999	\N	\N	llama	2025-09-16 23:56:15.822822+00
2280	aave:USDC	0.02527906	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.830945+00
2283	aave:USDC	0.04458639	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.830945+00
2285	aave:USDC	0.05559950	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.830945+00
2288	aave:USDC	0.05166565	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.830945+00
2289	aave:USDC	0.03475914	2025-09-16 23:56:12.975+00	2025-09-16 23:56:15.711293+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.830945+00
2290	justlend:USDD	0.00001492	2025-09-16 23:56:13.672+00	2025-09-16 23:56:15.711293+00	justlend	tron	USDD	1.4920728142131523e-05	\N	0	justlend	2025-09-16 23:56:15.836567+00
2291	justlend:USDT	0.01576513	2025-09-16 23:56:13.672+00	2025-09-16 23:56:15.711293+00	justlend	tron	USDT	0.015889709243331662	\N	0	justlend	2025-09-16 23:56:15.84344+00
2300	aave:AUSD	0.04469977	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	avalanche	AUSD	0.04571099262127798	\N	\N	onchain	2025-09-16 23:56:15.846864+00
2292	stride:stATOM	0.15140000	2025-09-16 23:56:12.982+00	2025-09-16 23:56:15.711293+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 23:56:15.848893+00
2293	stride:stTIA	0.11000000	2025-09-16 23:56:12.982+00	2025-09-16 23:56:15.711293+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 23:56:15.857135+00
2294	stride:stJUNO	0.22620000	2025-09-16 23:56:12.982+00	2025-09-16 23:56:15.711293+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 23:56:15.867491+00
2295	stride:stLUNA	0.17720000	2025-09-16 23:56:12.982+00	2025-09-16 23:56:15.711293+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 23:56:15.873952+00
2297	aave:USDT	0.05072927	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.877964+00
2302	aave:USDT	0.08514340	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.877964+00
2304	aave:USDT	0.03182836	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	avalanche	USDT	0.0323403	\N	\N	llama	2025-09-16 23:56:15.877964+00
2296	stride:stBAND	0.15430000	2025-09-16 23:56:12.982+00	2025-09-16 23:56:15.711293+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 23:56:15.881553+00
2299	aave:DAI	0.03517348	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	ethereum	DAI	0.04136599999999999	\N	\N	llama	2025-09-16 23:56:15.885525+00
2305	aave:DAI	0.04053331	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	ethereum	DAI	0.04136599999999999	\N	\N	llama	2025-09-16 23:56:15.885525+00
2298	aave:USDC	0.02527906	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.896776+00
2301	aave:USDC	0.04458639	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.896776+00
2303	aave:USDC	0.05559950	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.896776+00
2306	aave:USDC	0.05166565	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.896776+00
2307	aave:USDC	0.03475914	2025-09-16 23:56:12.985+00	2025-09-16 23:56:15.822839+00	aave	celo	USDC	0.0353703	\N	\N	llama	2025-09-16 23:56:15.896776+00
2308	justlend:USDD	0.00001492	2025-09-16 23:56:13.419+00	2025-09-16 23:56:15.822839+00	justlend	tron	USDD	1.4920728142131523e-05	\N	0	justlend	2025-09-16 23:56:15.901855+00
2309	justlend:USDT	0.01576513	2025-09-16 23:56:13.419+00	2025-09-16 23:56:15.822839+00	justlend	tron	USDT	0.015889709243331662	\N	0	justlend	2025-09-16 23:56:15.906661+00
2310	stride:stATOM	0.15140000	2025-09-16 23:56:12.986+00	2025-09-16 23:56:15.822839+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-16 23:56:15.9114+00
2311	stride:stTIA	0.11000000	2025-09-16 23:56:12.986+00	2025-09-16 23:56:15.822839+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-16 23:56:15.915857+00
2312	stride:stJUNO	0.22620000	2025-09-16 23:56:12.986+00	2025-09-16 23:56:15.822839+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-16 23:56:15.921392+00
2313	stride:stLUNA	0.17720000	2025-09-16 23:56:12.986+00	2025-09-16 23:56:15.822839+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-16 23:56:15.926516+00
2314	stride:stBAND	0.15430000	2025-09-16 23:56:12.986+00	2025-09-16 23:56:15.822839+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-16 23:56:15.930848+00
2318	aave:AUSD	0.05245950	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	avalanche	AUSD	0.05385590780470695	\N	\N	onchain	2025-09-17 19:27:36.187632+00
2315	aave:USDT	0.04806526	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.19841+00
2317	aave:DAI	0.03356529	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	ethereum	DAI	0.0409164	\N	\N	llama	2025-09-17 19:27:36.200861+00
2316	aave:USDC	0.02536499	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.205374+00
2320	aave:USDC	0.04867387	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.205374+00
2321	aave:USDC	0.05451176	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.205374+00
2319	aave:USDT	0.04771435	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.19841+00
2322	aave:USDT	0.03032618	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.19841+00
2323	aave:DAI	0.04010148	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	ethereum	DAI	0.0409164	\N	\N	llama	2025-09-17 19:27:36.200861+00
2324	aave:USDC	0.04976921	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.205374+00
2325	aave:USDC	0.03476020	2025-09-17 19:27:34.509+00	2025-09-17 19:27:36.166825+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.205374+00
2326	justlend:USDD	0.00001506	2025-09-17 19:27:34.768+00	2025-09-17 19:27:36.166825+00	justlend	tron	USDD	1.5059541180972857e-05	\N	0	justlend	2025-09-17 19:27:36.208741+00
2327	justlend:USDT	0.01577517	2025-09-17 19:27:34.768+00	2025-09-17 19:27:36.166825+00	justlend	tron	USDT	0.015899909487127717	\N	0	justlend	2025-09-17 19:27:36.211425+00
2328	stride:stATOM	0.15140000	2025-09-17 19:27:34.515+00	2025-09-17 19:27:36.166825+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-17 19:27:36.215199+00
2329	stride:stTIA	0.11000000	2025-09-17 19:27:34.515+00	2025-09-17 19:27:36.166825+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-17 19:27:36.21985+00
2330	stride:stJUNO	0.22620000	2025-09-17 19:27:34.515+00	2025-09-17 19:27:36.166825+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-17 19:27:36.223514+00
2331	stride:stLUNA	0.17720000	2025-09-17 19:27:34.515+00	2025-09-17 19:27:36.166825+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-17 19:27:36.226017+00
2332	stride:stBAND	0.15430000	2025-09-17 19:27:34.515+00	2025-09-17 19:27:36.166825+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-17 19:27:36.228763+00
2336	aave:AUSD	0.05245950	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	avalanche	AUSD	0.05385590780470695	\N	\N	onchain	2025-09-17 19:27:36.526893+00
2354	aave:AUSD	0.05245950	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	avalanche	AUSD	0.05385590780470695	\N	\N	onchain	2025-09-17 19:27:36.533244+00
2333	aave:USDT	0.04806526	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.537167+00
2337	aave:USDT	0.04771435	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.537167+00
2340	aave:USDT	0.03032618	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.537167+00
2335	aave:DAI	0.03356529	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	ethereum	DAI	0.0409164	\N	\N	llama	2025-09-17 19:27:36.53993+00
2341	aave:DAI	0.04010148	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	ethereum	DAI	0.0409164	\N	\N	llama	2025-09-17 19:27:36.53993+00
2351	aave:USDT	0.04806526	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.544503+00
2355	aave:USDT	0.04771435	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.544503+00
2358	aave:USDT	0.03032618	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	avalanche	USDT	0.0307907	\N	\N	llama	2025-09-17 19:27:36.544503+00
2334	aave:USDC	0.02536499	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.54573+00
2338	aave:USDC	0.04867387	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.54573+00
2339	aave:USDC	0.05451176	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.54573+00
2342	aave:USDC	0.04976921	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.54573+00
2343	aave:USDC	0.03476020	2025-09-17 19:27:34.53+00	2025-09-17 19:27:36.38145+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.54573+00
2353	aave:DAI	0.03356529	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	ethereum	DAI	0.0409164	\N	\N	llama	2025-09-17 19:27:36.546934+00
2359	aave:DAI	0.04010148	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	ethereum	DAI	0.0409164	\N	\N	llama	2025-09-17 19:27:36.546934+00
2344	justlend:USDD	0.00001506	2025-09-17 19:27:34.849+00	2025-09-17 19:27:36.38145+00	justlend	tron	USDD	1.5059541180972857e-05	\N	0	justlend	2025-09-17 19:27:36.548432+00
2345	justlend:USDT	0.01577517	2025-09-17 19:27:34.849+00	2025-09-17 19:27:36.38145+00	justlend	tron	USDT	0.015899909487127717	\N	0	justlend	2025-09-17 19:27:36.550878+00
2352	aave:USDC	0.02536499	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.552032+00
2356	aave:USDC	0.04867387	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.552032+00
2357	aave:USDC	0.05451176	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.552032+00
2360	aave:USDC	0.04976921	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.552032+00
2361	aave:USDC	0.03476020	2025-09-17 19:27:34.516+00	2025-09-17 19:27:36.51854+00	aave	celo	USDC	0.0353714	\N	\N	llama	2025-09-17 19:27:36.552032+00
2346	stride:stATOM	0.15140000	2025-09-17 19:27:34.532+00	2025-09-17 19:27:36.38145+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-17 19:27:36.553089+00
2362	justlend:USDD	0.00001506	2025-09-17 19:27:34.77+00	2025-09-17 19:27:36.51854+00	justlend	tron	USDD	1.5059541180972857e-05	\N	0	justlend	2025-09-17 19:27:36.55429+00
2347	stride:stTIA	0.11000000	2025-09-17 19:27:34.532+00	2025-09-17 19:27:36.38145+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-17 19:27:36.55549+00
2363	justlend:USDT	0.01577517	2025-09-17 19:27:34.77+00	2025-09-17 19:27:36.51854+00	justlend	tron	USDT	0.015899909487127717	\N	0	justlend	2025-09-17 19:27:36.556407+00
2348	stride:stJUNO	0.22620000	2025-09-17 19:27:34.532+00	2025-09-17 19:27:36.38145+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-17 19:27:36.557674+00
2364	stride:stATOM	0.15140000	2025-09-17 19:27:34.518+00	2025-09-17 19:27:36.51854+00	stride	cosmos	stATOM	0.1634254278281715	\N	\N	stride	2025-09-17 19:27:36.559347+00
2349	stride:stLUNA	0.17720000	2025-09-17 19:27:34.532+00	2025-09-17 19:27:36.38145+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-17 19:27:36.560405+00
2365	stride:stTIA	0.11000000	2025-09-17 19:27:34.518+00	2025-09-17 19:27:36.51854+00	stride	cosmos	stTIA	0.11625957163742662	\N	\N	stride	2025-09-17 19:27:36.561625+00
2350	stride:stBAND	0.15430000	2025-09-17 19:27:34.532+00	2025-09-17 19:27:36.38145+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-17 19:27:36.562867+00
2366	stride:stJUNO	0.22620000	2025-09-17 19:27:34.518+00	2025-09-17 19:27:36.51854+00	stride	cosmos	stJUNO	0.25373856288953367	\N	\N	stride	2025-09-17 19:27:36.564118+00
2367	stride:stLUNA	0.17720000	2025-09-17 19:27:34.518+00	2025-09-17 19:27:36.51854+00	stride	cosmos	stLUNA	0.1938185084420403	\N	\N	stride	2025-09-17 19:27:36.566385+00
2368	stride:stBAND	0.15430000	2025-09-17 19:27:34.518+00	2025-09-17 19:27:36.51854+00	stride	cosmos	stBAND	0.16680284210355034	\N	\N	stride	2025-09-17 19:27:36.567965+00
\.


--
-- Name: allocation_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.allocation_history_id_seq', 170, true);


--
-- Name: allocation_targets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.allocation_targets_id_seq', 3, true);


--
-- Name: allocations_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.allocations_history_id_seq', 12, true);


--
-- Name: delegations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.delegations_id_seq', 1, false);


--
-- Name: exchanges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exchanges_id_seq', 1, false);


--
-- Name: gov_allocation_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gov_allocation_history_id_seq', 1, false);


--
-- Name: gov_execution_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gov_execution_queue_id_seq', 1, false);


--
-- Name: gov_power_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gov_power_snapshots_id_seq', 10, true);


--
-- Name: gov_proposals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gov_proposals_id_seq', 10, true);


--
-- Name: liquidity_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.liquidity_events_id_seq', 9, true);


--
-- Name: pi_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pi_payments_id_seq', 2, true);


--
-- Name: planned_actions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.planned_actions_id_seq', 9, true);


--
-- Name: pps_series_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pps_series_id_seq', 26, true);


--
-- Name: proposal_status_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proposal_status_history_id_seq', 1, false);


--
-- Name: rebalance_plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rebalance_plans_id_seq', 9, true);


--
-- Name: redemptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.redemptions_id_seq', 14, true);


--
-- Name: stakes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stakes_id_seq', 18, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: venue_rates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venue_rates_id_seq', 2368, true);


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
-- Name: liquidity_events liquidity_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liquidity_events
    ADD CONSTRAINT liquidity_events_pkey PRIMARY KEY (id);


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

\unrestrict mUBfqcwnEZfakXjC5l8aKKHGJnZVRT4mYeuz5BgUVTVCVStL5OSwVCeU7TKdPvN

