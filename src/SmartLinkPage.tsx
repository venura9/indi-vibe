import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import {
  siSpotify,
  siApplemusic,
  siTidal,
  siAmazonmusic,
  siYoutube,
  siYoutubemusic,
  siInstagram,
  siFacebook,
  siTiktok,
} from 'simple-icons'

interface ArtistData {
  id: string
  artistName: string
  releaseTitle: string
  coverArtUrl: string
  platforms: Record<string, string>
  socials: Record<string, string>
}

const PLATFORM_ICONS: Record<string, { path: string; color: string }> = {
  Spotify: { path: siSpotify.path, color: '#1DB954' },
  'Apple Music': { path: siApplemusic.path, color: '#FC3C44' },
  TIDAL: { path: siTidal.path, color: '#00FFFF' },
  'Amazon Music': { path: siAmazonmusic.path, color: '#00A8E1' },
  YouTube: { path: siYoutube.path, color: '#FF0000' },
  'YouTube Music': { path: siYoutubemusic.path, color: '#FF0000' },
}

const SOCIAL_ICONS: Record<string, { path: string; color: string }> = {
  YouTube: { path: siYoutube.path, color: '#FF0000' },
  Spotify: { path: siSpotify.path, color: '#1DB954' },
  TikTok: { path: siTiktok.path, color: '#69C9D0' },
  Facebook: { path: siFacebook.path, color: '#1877F2' },
  Instagram: { path: siInstagram.path, color: '#E4405F' },
}

function PlatformIcon({ path, color }: { path: string; color: string }) {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" fill={color}>
      <path d={path} />
    </svg>
  )
}

export default function SmartLinkPage() {
  const { slug } = useParams<{ slug?: string }>()
  const effectiveSlug = slug || 'yumethvoicetales'

  const [data, setData] = useState<ArtistData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    setLoading(true)
    setError(null)
    fetch(`/api/links/${effectiveSlug}`)
      .then((res) => {
        if (!res.ok) throw new Error(res.status === 404 ? 'Artist not found' : 'Failed to load')
        return res.json() as Promise<ArtistData>
      })
      .then(setData)
      .catch((err: Error) => setError(err.message))
      .finally(() => setLoading(false))
  }, [effectiveSlug])

  if (loading) {
    return (
      <div style={styles.center}>
        <div style={styles.spinner} />
      </div>
    )
  }

  if (error || !data) {
    return (
      <div style={styles.center}>
        <p style={{ color: '#999', fontSize: '1.1rem' }}>{error ?? 'Not found'}</p>
      </div>
    )
  }

  return (
    <div style={styles.page}>
      <div style={styles.card}>
        {/* Card suit decoration */}
        <div style={styles.suitTopLeft}>♠</div>
        <div style={styles.suitBottomRight}>♠</div>

        {/* Cover art */}
        <img
          src={data.coverArtUrl}
          alt={`${data.releaseTitle} cover art`}
          style={styles.coverArt}
        />

        {/* Artist info */}
        <h1 style={styles.artistName}>{data.artistName}</h1>
        <h2 style={styles.releaseTitle}>{data.releaseTitle}</h2>

        <div style={styles.divider} />

        {/* Streaming platforms */}
        <section style={styles.section}>
          <p style={styles.sectionLabel}>Listen on</p>
          <div style={styles.buttonGrid}>
            {Object.entries(data.platforms).map(([name, url]) => {
              const icon = PLATFORM_ICONS[name]
              return (
                <a key={name} href={url} target="_blank" rel="noopener noreferrer" style={styles.platformBtn}>
                  {icon && <PlatformIcon path={icon.path} color={icon.color} />}
                  <span>{name}</span>
                </a>
              )
            })}
          </div>
        </section>

        <div style={styles.divider} />

        {/* Social links */}
        <section style={styles.section}>
          <p style={styles.sectionLabel}>Follow</p>
          <div style={styles.socialRow}>
            {Object.entries(data.socials).map(([name, url]) => {
              const icon = SOCIAL_ICONS[name]
              return (
                <a key={name} href={url} target="_blank" rel="noopener noreferrer" style={styles.socialBtn} title={name}>
                  {icon && <PlatformIcon path={icon.path} color={icon.color} />}
                </a>
              )
            })}
          </div>
        </section>
      </div>
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  center: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
  },
  spinner: {
    width: 40,
    height: 40,
    border: '3px solid #333',
    borderTop: '3px solid #c9a84c',
    borderRadius: '50%',
    animation: 'spin 0.8s linear infinite',
  },
  page: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
    padding: '1.5rem',
  },
  card: {
    position: 'relative',
    background: 'linear-gradient(145deg, #16161e 0%, #0d0d14 100%)',
    border: '1px solid #2a2a3a',
    borderRadius: '1.25rem',
    boxShadow: '0 8px 40px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.05)',
    padding: '2.5rem 2rem',
    maxWidth: '420px',
    width: '100%',
    textAlign: 'center',
  },
  suitTopLeft: {
    position: 'absolute',
    top: '0.75rem',
    left: '1rem',
    fontSize: '1.2rem',
    color: '#c9a84c',
    opacity: 0.6,
  },
  suitBottomRight: {
    position: 'absolute',
    bottom: '0.75rem',
    right: '1rem',
    fontSize: '1.2rem',
    color: '#c9a84c',
    opacity: 0.6,
    transform: 'rotate(180deg)',
  },
  coverArt: {
    width: '160px',
    height: '160px',
    objectFit: 'cover',
    borderRadius: '0.75rem',
    boxShadow: '0 4px 20px rgba(0,0,0,0.5)',
    marginBottom: '1.25rem',
  },
  artistName: {
    fontSize: '1.4rem',
    fontWeight: 700,
    color: '#f0e6c8',
    letterSpacing: '0.02em',
    marginBottom: '0.25rem',
  },
  releaseTitle: {
    fontSize: '1rem',
    fontWeight: 400,
    color: '#c9a84c',
    letterSpacing: '0.08em',
    textTransform: 'uppercase',
    marginBottom: '1.5rem',
  },
  divider: {
    height: '1px',
    background: 'linear-gradient(90deg, transparent, #2a2a3a, transparent)',
    margin: '1.25rem 0',
  },
  section: {
    marginBottom: '0.5rem',
  },
  sectionLabel: {
    fontSize: '0.7rem',
    letterSpacing: '0.15em',
    textTransform: 'uppercase',
    color: '#666',
    marginBottom: '0.75rem',
  },
  buttonGrid: {
    display: 'flex',
    flexDirection: 'column',
    gap: '0.5rem',
  },
  platformBtn: {
    display: 'flex',
    alignItems: 'center',
    gap: '0.75rem',
    padding: '0.65rem 1rem',
    background: 'rgba(255,255,255,0.04)',
    border: '1px solid rgba(255,255,255,0.08)',
    borderRadius: '0.5rem',
    color: '#e0e0e0',
    textDecoration: 'none',
    fontSize: '0.9rem',
    transition: 'background 0.15s, border-color 0.15s',
    cursor: 'pointer',
  },
  socialRow: {
    display: 'flex',
    justifyContent: 'center',
    gap: '1rem',
    flexWrap: 'wrap',
  },
  socialBtn: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: '40px',
    height: '40px',
    background: 'rgba(255,255,255,0.05)',
    border: '1px solid rgba(255,255,255,0.1)',
    borderRadius: '50%',
    textDecoration: 'none',
    transition: 'background 0.15s',
  },
}
