const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  mode: "jit",
  purge: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        'darkness': {
          'DEFAULT': "#2E2E2E",
          '50': '#8A8A8A',
          '100': '#808080',
          '200': '#6B6B6B',
          '300': '#575757',
          '400': '#424242',
          '500': '#2E2E2E',
          '600': '#121212',
          '700': '#000000',
          '800': '#000000',
          '900': '#000000'
        },
        'lime': {
          'DEFAULT': "#CFFF60",
          '50': '#fdfff7',
          '100': '#faffef',
          '200': '#f3ffd7',
          '300': '#ecffbf',
          '400': '#ddff90',
          '500': '#CFFF60',
          '600': '#bae656',
          '700': '#9bbf48',
          '800': '#7c993a',
          '900': '#657d2f'
        }
      },
      fontFamily: {
        serif: [
          'Libre Baskerville',
          ...defaultTheme.fontFamily.serif
        ],
        sans: [
          'Inter var',
          ...defaultTheme.fontFamily.sans
        ],
        mono: [
          'Space Mono',
          ...defaultTheme.fontFamily.mono
        ]
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
};
