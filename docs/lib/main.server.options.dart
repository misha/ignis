// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:docs/components/callouts.dart' as _callouts;
import 'package:docs/components/coverage.dart' as _coverage;
import 'package:docs/components/demo.dart' as _demo;
import 'package:docs/components/drag_and_drop_demo.dart' as _drag_and_drop_demo;
import 'package:docs/components/reference.dart' as _reference;
import 'package:docs/components/related.dart' as _related;
import 'package:docs/components/scene_demo.dart' as _scene_demo;
import 'package:docs/components/status_banner.dart' as _status_banner;
import 'package:docs/theme.dart' as _theme;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    as _code_block_copy_button;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as _zoomable_image;
import 'package:jaspr_content/components/callout.dart' as _callout;
import 'package:jaspr_content/components/code_block.dart' as _code_block;
import 'package:jaspr_content/components/github_button.dart' as _github_button;
import 'package:jaspr_content/components/image.dart' as _image;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    as _sidebar_toggle_button;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _drag_and_drop_demo.DragAndDropDemo:
        ClientTarget<_drag_and_drop_demo.DragAndDropDemo>('drag_and_drop_demo'),
    _scene_demo.SceneDemo: ClientTarget<_scene_demo.SceneDemo>(
      'scene_demo',
      params: __scene_demoSceneDemo,
    ),
    _code_block_copy_button.CodeBlockCopyButton:
        ClientTarget<_code_block_copy_button.CodeBlockCopyButton>(
          'jaspr_content:code_block_copy_button',
        ),
    _zoomable_image.ZoomableImage: ClientTarget<_zoomable_image.ZoomableImage>(
      'jaspr_content:zoomable_image',
      params: __zoomable_imageZoomableImage,
    ),
    _github_button.GitHubButton: ClientTarget<_github_button.GitHubButton>(
      'jaspr_content:github_button',
      params: __github_buttonGitHubButton,
    ),
    _sidebar_toggle_button.SidebarToggleButton:
        ClientTarget<_sidebar_toggle_button.SidebarToggleButton>(
          'jaspr_content:sidebar_toggle_button',
        ),
  },
  styles: () => [
    ..._theme.IgnisStyles.styles,
    ..._callouts.Callouts.styles,
    ..._coverage.Coverage.styles,
    ..._demo.Demo.styles,
    ..._drag_and_drop_demo.DragAndDropDemoState.styles,
    ..._reference.Reference.styles,
    ..._related.Related.styles,
    ..._scene_demo.SceneDemo.styles,
    ..._status_banner.StatusBanner.styles,
    ..._callout.Callout.styles,
    ..._code_block.CodeBlock.styles,
    ..._github_button.GitHubButton.styles,
    ..._image.Image.styles,
    ..._zoomable_image.ZoomableImage.styles,
  ],
);

Map<String, Object?> __scene_demoSceneDemo(_scene_demo.SceneDemo c) => {
  'name': c.name,
};
Map<String, Object?> __zoomable_imageZoomableImage(
  _zoomable_image.ZoomableImage c,
) => {'src': c.src, 'alt': c.alt, 'caption': c.caption};
Map<String, Object?> __github_buttonGitHubButton(
  _github_button.GitHubButton c,
) => {'repo': c.repo};
