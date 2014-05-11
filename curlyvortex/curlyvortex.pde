/*
 *      Copyright (C) 2014 Stephen M. Cameron
 *      Author: Stephen M. Cameron
 *
 *      This file is part of curly-vortex.
 *
 *      curly-vortex is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      curly-vortex is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with curly-vortex if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/*
 * This work is based on the paper "Curl-Noise for Procedural Fluid Flow"
 * by Bridson, Hourihan, and Nordenstam.
 * 
 * See: https://www.cct.lsu.edu/~fharhad/ganbatte/siggraph2007/CD2/content/papers/046-bridson.pdf
 */

/* user adjustable parameters */
String source_image_file = "/home/scameron/test.jpg";
int xdim = 1000;
int ydim = 600;
int nparticles = 2000000;
int framenumber = 0;
PImage source_color = loadImage(source_image_file);
float noise_scale = 8.0; /* xdim / 100 is not a bad default. */
float velocity_amplification = 15.0; /* xdim / 50 is not a bad default. */
int image_snapshot_period = 0;
int background_alpha = 5; /* between 0 and 255, needs to be a low number. */
int numbands = 4;
float bandfactor = 0.3;

/* vx, vy are the velocity field */
float[][] vx = new float[xdim][ydim];
float[][] vy = new float[xdim][ydim];

/* px,py,pc are particle coords and color */
float[] px = new float[nparticles];
float[] py = new float[nparticles];
int pl[] = new int[nparticles]; /* particle lifetime, not used */
color pc[] = new color[nparticles];

float c;

PImage img;

void setup()
{
	int cx, cy;

	size(xdim, ydim);
	frameRate(30);
	img = createImage(xdim, ydim, ARGB); 
	img.loadPixels();
	for (int j = 0; j < img.pixels.length; j++) {
		img.pixels[j] = color(0, 0, 0, 255);
	}
	img.updatePixels();

	for (int i = 0; i < nparticles; i++) {
		px[i] = random(xdim);
		py[i] = random(ydim);
		//pl[i] = int(random(nparticles / 100));
		pl[i] = 1000;
		if (source_color != null) {
			cx = int(float(source_color.width) * px[i] / float(xdim));
			cy = int(float(source_color.height) * py[i] / float(ydim));
			pc[i] = source_color.pixels[cy * source_color.width + cx]; 
		} else {
			pc[i] = color((px[i] / 5) % 100 + 100,
				255 - (px[i] + py[i] / 2) % 255,
				(500 - (px[i]) % 255) / 2, 40);
		}
	}
	c = 1.3;
}

void update_velocity_field()
{ 
	int x, y, r, g, b;
	float nxscale = noise_scale;
	float nyscale = nxscale * float(ydim) / float(xdim);
	float amp = velocity_amplification;
	float fx1, fy1, fx2, fy2, n1, n2, nx, ny, v, dx, dy;

	for (x = 0; x < xdim; x++) {
		for (y = 0; y < ydim; y++) {
			/* Calculate gradient of noise field at x,y.
			 * fx1,fy1, fx2,fy2 are points diagonally near x,y
			 * Add slight amount of randomness (dx,dy) to hide banding of perlin noise
			 */
			dx =  (random(100) * 0.005) - 0.25;
			dy =  (random(100) * 0.005) - 0.25;
			fx1 = ((float(x - 1) + dx) / float(xdim)) * nxscale;
			fy1 = ((float(y - 1) + dy) / float(ydim)) * nyscale;
			dx =  (random(100) * 0.005) - 0.25;
			dy =  (random(100) * 0.005) - 0.25;
			fx2 = ((float(x + 1) + dx) / float(xdim)) * nxscale;
			fy2 = ((float(y + 1) + dy) / float(ydim)) * nyscale;

			/* Calculate deltax of noise at x,y and deltay at x,y
			 * (-deltax, deltay) is the curl of the noise field at x,y.
			 */
			n1 = noise(fx1, fy1, c);
			n2 = noise(fx2, fy1, c);
			ny = -amp * (n2 - n1);
			n1 = noise(fx1, fy1, c);
			n2 = noise(fx1, fy2, c);
			nx = amp * (n2 - n1);

			/* Use the curl of the noise field as velocity.
			 * but modulate with bands of horizontal velocity
			 */
			vx[x][y] = nx + bandfactor *
				cos((float) y / (float) ydim * numbands * 3.141527);
			vy[x][y] = ny;
		}
	}
	c = c + 0.009;
} 

color heatmap(float val, float alpha, float multiplier)
{
	float r, g, b;

	b = 255.0 * (1.0 - val / 0.5) + 30;
	if (b < 0)
		b = 0;
	r = 255.0 * (val / 0.5 - 0.5) + 30;
	if (r < 0)
		r = 0;
	g = 255.0 - r / 2.5 - b / 2.5;
	return color(int(r * multiplier), int(g * multiplier), int(b * multiplier), alpha);
}


void draw()
{
	float ivx, ivy, v;
	int tx, ty;
	color clr;

	tx = 0;
	ty = 0;
	if ((framenumber % 20) == 0) {
		update_velocity_field();
	}

	/* slowly fade out image */
	for (int j = 0; j < img.pixels.length; j++) {
		ivx = vx[tx][ty];
		ivy = vy[tx][ty];
		v = sqrt(ivx * ivx + ivy * ivy);
		if (v > 6.0)
			v = 6.0;
		clr = heatmap(v / 2.0, background_alpha, 0.0);
		//clr = color(5, 5, 5, 0.1);
		img.pixels[j] = clr;
		tx++;
		if (tx >= xdim) {
			tx = 0;
			ty++;
		}
	}
	img.updatePixels();

	/* move particles */
	for (int i = 0; i < nparticles; i++) {

		/* wrap particles at image edges */
		tx = int(px[i]);
		ty = int(py[i]);
		if (tx >= xdim)
			tx = tx - xdim;
		if (ty >= ydim)
			ty = ty - ydim;
		if (tx < 0)
			tx = tx + xdim;
		if (ty < 0)
			ty = ty + ydim;

		/* Move particles according to velocity field at current location */
		ivx = vx[tx][ty];
		ivy = vy[tx][ty];
		px[i] += ivx;
		py[i] += ivy;
/*
		v = sqrt(ivx * ivx + ivy * ivy);
		if (v > 6.0)
			v = 6.0;
		clr = heatmap(v / 2.0, 200, 0.9);
*/
		clr = pc[i];

		/* update image color according to particle color */
		img.pixels[xdim * ty + tx] = clr;

		/* age particles (not used) */
		//pl[i]--;
		if (pl[i] <= 0) {
			px[i] = random(xdim);
			py[i] = random(ydim);
			//pl[i] = int(random(nparticles / 100));
			pl[i] = 100;
		}
	}
	img.updatePixels();
	image(img, 0, 0);
	if (image_snapshot_period != 0 &&
		(framenumber % image_snapshot_period) == 0) {
		save("image" + (10000 + framenumber) + ".png");
	}
	framenumber++;
}

