<script lang="ts">
  import { ProfileForm } from '$features/update-profile'
  import { TagsSettings } from '$features/manage-tags'
  import { i18n } from '$shared/lib/i18n'
</script>

<div class="main-inner">
  <div class="page-header">
    <div class="page-header-left">
      <div class="page-eyebrow">{i18n.t('settings.eyebrow')}</div>
      <h1 class="page-title"><em>{i18n.t('settings.title')}</em></h1>
    </div>
  </div>

  <section class="section">
    <div class="section-header">
      <h2 class="section-title">{i18n.t('settings.profile')}</h2>
      <span class="section-meta">{i18n.t('settings.profile_meta')}</span>
    </div>
    <ProfileForm />
  </section>

  <section class="section">
    <div class="section-header">
      <h2 class="section-title">{i18n.t('settings.tags')}</h2>
      <span class="section-meta">{i18n.t('settings.tags_meta')}</span>
    </div>
    <TagsSettings />
  </section>

  <section class="section">
    <div class="section-header">
      <h2 class="section-title">{i18n.t('settings.tasks')}</h2>
      <span class="section-meta">{i18n.t('settings.tasks_meta')}</span>
    </div>
    <p class="text-[13px] text-muted">{i18n.t('settings.recurring_wip')}</p>
  </section>
</div>
