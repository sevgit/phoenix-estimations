/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      backgroundImage: {
        "estimation-gradient":
          "linear-gradient(43deg, #4158D0 0%, #C850C0 46%, #FFCC70 100%)",
        "participant-gradient":
          "linear-gradient(62deg, #FBAB7E 0%, #F7CE68 100%)",
      },
      colors: {
        goldenrod: {
          DEFAULT: "#E6AF2E",
        },
      },
      animation: {
        "ping-once": "ping 1s cubic-bezier(0.4, 0, 0.6, 1) reverse",
      },
    },
  },
  plugins: [],
};
