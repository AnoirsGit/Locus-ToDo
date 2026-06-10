<script lang="ts">
  import { ProfileForm } from '$features/update-profile'
  import { TagsSettings } from '$features/manage-tags'
</script>

<div class="main-inner">
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">Профиль + настройки</div>
      <h1 class="page-title"><em>Настройки.</em></h1>
    </div>
  </div>

  <section class="section">
    <div class="section-header">
      <h2 class="section-title">Профиль</h2>
      <span class="section-meta">кто ты есть</span>
    </div>
    <ProfileForm />
  </section>

  <section class="section">
    <div class="section-header">
      <h2 class="section-title">Tags</h2>
      <span class="section-meta">labels for tasks</span>
    </div>
    <TagsSettings />
  </section>

  <section class="section">
    <div class="section-header">
      <h2 class="section-title">Задачи</h2>
      <span class="section-meta">автоматизация</span>
    </div>
    <p class="text-[13px] text-muted">Управление повторяющимися задачами — в разработке.</p>
  </section>
</div>
