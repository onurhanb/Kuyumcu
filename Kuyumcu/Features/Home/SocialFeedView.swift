import SwiftUI

struct SocialFeedView: View {
    @Binding var isPresented: Bool

    @State private var posts: [SocialFeedPost] = []
    @State private var isLoading = false
    @State private var hasLoaded = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                header
                Divider().background(Color.gdlDivider)
                content
            }
            .frame(maxHeight: 620)
            .background(LinearGradient.gdlOuterSurface)
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.shellOuterRadius))
            .padding(.horizontal, 18)
            .shadow(color: .black.opacity(0.42), radius: 24, x: 0, y: 8)
        }
        .task {
            await loadPostsIfNeeded()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundColor(.gdlGold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Kuyumcu Güncel")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.gdlTextPrimary)
                Text("Piyasa, başarılar ve duyurular")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
            }
            Spacer()
            Button { isPresented = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gdlTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView(showsIndicators: false) {
            if isLoading && posts.isEmpty {
                loadingState
            } else if posts.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(posts) { post in
                        SocialPostCard(post: post)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
        }
        .refreshable {
            await refreshPosts()
        }
    }

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView().tint(.gdlGold)
            Text("Akış yükleniyor...")
                .font(.gdlBody())
                .foregroundColor(.gdlTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.gdlGold.opacity(0.85))
            Text("Henüz paylaşım yok")
                .font(.gdlHeadline())
                .foregroundColor(.gdlTextPrimary)
            Text("Kuyumcu Güncel yeni haberleri ve günlük özetleri burada paylaşacak.")
                .font(.gdlCaption())
                .foregroundColor(.gdlTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }

    private func loadPostsIfNeeded() async {
        guard !hasLoaded else { return }
        isLoading = true
        defer { isLoading = false }
        await refreshPosts()
    }

    /// Pull-to-refresh iptalinde (CancellationError) mevcut listeyi korur.
    private func refreshPosts() async {
        do {
            let fetchedPosts = try await SupabaseSaveService.fetchSocialFeedPosts()
            posts = fetchedPosts
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            print("[SocialFeed] yenileme hata:", error.localizedDescription)
        }
    }
}

private struct SocialPostCard: View {
    let post: SocialFeedPost

    private var reactionCounts: (comments: Int, reposts: Int, likes: Int) {
        let seed = post.id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (
            comments: seed % 9 + 1,
            reposts: seed / 11 % 14 + 2,
            likes: seed / 37 % 28 + 4
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.authorName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.gdlTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(post.authorHandle)
                            .lineLimit(1)
                        Text("·")
                        Text(relativeDateText)
                            .lineLimit(1)
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gdlTextSecondary)
                }
                .frame(maxHeight: 46)

                Spacer(minLength: 0)
            }

            Text(post.body)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.gdlTextPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 26) {
                reaction(icon: "bubble.left", value: reactionCounts.comments)
                reaction(icon: "arrow.2.squarepath", value: reactionCounts.reposts)
                reaction(icon: "heart", value: reactionCounts.likes)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color.gdlCardSecondary.opacity(0.58))
        .overlay(
            RoundedRectangle(cornerRadius: GDLRadius.md)
                .stroke(Color.gdlGold.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: GDLRadius.md))
    }

    private var avatar: some View {
        ZStack {
            if let assetName = avatarAssetName,
               UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gdlGoldLight, Color.gdlGold, Color(red: 0.28, green: 0.20, blue: 0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: avatarIconName)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.black.opacity(0.82))
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }

    private var avatarAssetName: String? {
        switch post.authorAvatarKey {
        case "kuyumcu_guncel":
            return "social_avatar_kuyumcu_guncel"
        default:
            return nil
        }
    }

    private var avatarIconName: String {
        switch post.authorAvatarKey {
        case "announcement":
            return "megaphone.fill"
        default:
            return "newspaper.fill"
        }
    }

    private func reaction(icon: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text("\(value)")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.gdlTextSecondary)
    }

    private var relativeDateText: String {
        let elapsed = Date().timeIntervalSince(post.publishedAt)
        if elapsed < 3_600 {
            return "\(max(1, Int(elapsed / 60)))dk"
        }
        if elapsed < 86_400 {
            return "\(max(1, Int(elapsed / 3_600)))sa"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: post.publishedAt)
    }
}
