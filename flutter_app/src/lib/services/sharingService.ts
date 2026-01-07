/**
 * Sharing Service
 * Handles social media publishing and sharing
 */

/**
 * Share to social media
 */
export async function shareToSocialMedia(
    platform: 'facebook' | 'twitter' | 'instagram' | 'linkedin',
    content: { title: string; description: string; url: string; imageUrl?: string }
): Promise<boolean> {
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // In production, integrate with respective APIs
    const shareUrls = {
        facebook: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(content.url)}`,
        twitter: `https://twitter.com/intent/tweet?text=${encodeURIComponent(content.title)}&url=${encodeURIComponent(content.url)}`,
        instagram: '', // Instagram requires app integration
        linkedin: `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(content.url)}`
    }
    
    if (shareUrls[platform]) {
        window.open(shareUrls[platform], '_blank')
        return true
    }
    
    return false
}

/**
 * Generate shareable link
 */
export function generateShareableLink(type: 'match' | 'player' | 'tournament', id: string): string {
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'https://cricplay.app'
    return `${baseUrl}/${type}/${id}`
}

/**
 * Copy to clipboard
 */
export async function copyToClipboard(text: string): Promise<boolean> {
    try {
        await navigator.clipboard.writeText(text)
        return true
    } catch (error) {
        console.error('Failed to copy:', error)
        return false
    }
}

