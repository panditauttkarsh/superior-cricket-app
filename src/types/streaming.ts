/**
 * Live Streaming types
 */

export interface Stream {
    id: string
    matchId: string
    title: string
    description: string
    streamUrl: string
    thumbnailUrl?: string
    quality: 'auto' | '1080p' | '720p' | '480p' | '360p'
    status: 'scheduled' | 'live' | 'ended' | 'recording'
    viewerCount: number
    startTime: string
    endTime?: string
    isRecording: boolean
    recordingUrl?: string
}

export interface StreamSettings {
    quality: 'auto' | '1080p' | '720p' | '480p' | '360p'
    autoplay: boolean
    showChat: boolean
    showStats: boolean
}

