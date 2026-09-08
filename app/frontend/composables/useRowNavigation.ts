import { useRouter } from 'vue-router'

// List rows are clickable for mouse users; each row also has a real <RouterLink>
// in one cell for keyboard and assistive tech. This handler navigates on a row
// click but bails when the click originated on that link, so it isn't handled
// twice.
export function useRowNavigation() {
  const router = useRouter()
  return function rowClick(e: MouseEvent, to: string) {
    if ((e.target as HTMLElement).closest('a')) return
    router.push(to)
  }
}
